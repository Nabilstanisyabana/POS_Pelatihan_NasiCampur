const express = require("express");
const cors = require("cors");
const http = require("http");
const crypto = require("crypto");
const { WebSocketServer } = require("ws");

const app = express();
app.use(cors());

// Simpan rawBody untuk verifikasi signature HMAC-SHA256 MiomiPay
app.use(
    express.json({
        verify: (req, res, buf) => {
            req.rawBody = buf;
        },
    })
);

const server = http.createServer(app);
const wss = new WebSocketServer({ server });

let counter = 0;
let history = [];
let clients = new Set();
const sseClients = new Set();

function publishData() {
    counter++;

    const data = {
        counter,
        value: Math.floor(Math.random() * 100),
        timestamp: new Date().toISOString(),
    };

    history.push(data);
    if (history.length > 100) history.shift();

    // Broadcast ke seluruh client WebSocket
    for (const client of clients) {
        if (client.readyState === 1) {
            client.send(JSON.stringify(data));
        }
    }

    // Kirim pembaruan ke koneksi SSE
    for (const res of sseClients) {
        res.write(`data: ${JSON.stringify(data)}\n\n`);
    }
}

setInterval(publishData, 3000);

// ============================================================================
// MiomiPay Gateway Backend API & Webhook
// Base URL: https://pg.miomidev.com/api/v1
// ============================================================================
const MIOMIPAY_BASE_URL =
    process.env.MIOMIPAY_BASE_URL || "https://pg.miomidev.com/api/v1";
const MIOMIPAY_API_KEY = process.env.MIOMIPAY_API_KEY || "";
const MIOMIPAY_WEBHOOK_SECRET = process.env.MIOMIPAY_WEBHOOK_SECRET || "";

/**
 * Endpoint membuat tagihan MiomiPay dari sisi backend (Aman: API Key tersimpan di server).
 * Method: POST /api/payment/create
 */
app.post("/api/payment/create", async (req, res) => {
    try {
        if (!MIOMIPAY_API_KEY) {
            return res.status(500).json({
                success: false,
                message:
                    "MIOMIPAY_API_KEY belum dikonfigurasi di server backend. Set environment variable MIOMIPAY_API_KEY.",
            });
        }

        const {
            external_id,
            amount,
            customer_name,
            customer_email,
            customer_phone,
            description,
            success_redirect_url,
        } = req.body;

        const response = await fetch(`${MIOMIPAY_BASE_URL}/payment/create`, {
            method: "POST",
            headers: {
                Authorization: `Bearer ${MIOMIPAY_API_KEY}`,
                "Content-Type": "application/json",
                Accept: "application/json",
            },
            body: JSON.stringify({
                external_id,
                amount,
                customer_name,
                customer_email,
                customer_phone,
                description,
                success_redirect_url,
            }),
        });

        const data = await response.json();
        return res.status(response.status).json(data);
    } catch (error) {
        return res.status(500).json({
            success: false,
            message: `Gagal membuat tagihan MiomiPay: ${error.message}`,
        });
    }
});

/**
 * Endpoint cek status tagihan ke MiomiPay dari sisi backend.
 * Method: GET /api/payment/:reference/status
 */
app.get("/api/payment/:reference/status", async (req, res) => {
    try {
        const { reference } = req.params;
        if (!MIOMIPAY_API_KEY) {
            return res.status(500).json({
                success: false,
                message: "MIOMIPAY_API_KEY belum dikonfigurasi di backend.",
            });
        }

        const response = await fetch(
            `${MIOMIPAY_BASE_URL}/payment/${reference}/status`,
            {
                method: "GET",
                headers: {
                    Authorization: `Bearer ${MIOMIPAY_API_KEY}`,
                    Accept: "application/json",
                },
            }
        );

        const data = await response.json();
        return res.status(response.status).json(data);
    } catch (error) {
        return res.status(500).json({
            success: false,
            message: `Gagal cek status: ${error.message}`,
        });
    }
});

/**
 * Webhook Receiver dari MiomiPay sesuai panduan:
 * Header:
 * - Content-Type: application/json
 * - X-MiomiPay-Event: payment.success (atau status perubahan)
 * - X-MiomiPay-Signature: <HMAC-SHA256 hex string>
 */
app.post("/api/payment/webhook", (req, res) => {
    const incomingSignature = req.headers["x-miomipay-signature"];
    const eventName = req.headers["x-miomipay-event"] || "payment.status_update";
    const secretKey = MIOMIPAY_WEBHOOK_SECRET;

    // Verifikasi Signature HMAC-SHA256 jika secret key disetel
    if (secretKey && req.rawBody) {
        const calculatedSignature = crypto
            .createHmac("sha256", secretKey)
            .update(req.rawBody)
            .digest("hex");

        if (
            !incomingSignature ||
            !crypto.timingSafeEqual(
                Buffer.from(calculatedSignature),
                Buffer.from(incomingSignature)
            )
        ) {
            console.warn(
                `[MiomiPay Webhook] Signature TIDAK VALID! Incoming: ${incomingSignature}`
            );
            return res.status(401).send("Invalid signature");
        }
    }

    const { data } = req.body || {};
    const reference = data?.reference;
    const status = (data?.status || "").toUpperCase();
    const externalId = data?.external_id;

    console.log(
        `[MiomiPay Webhook Diterima] Event: ${eventName} | Ref: ${reference} | External ID: ${externalId} | Status: ${status}`
    );

    // Broadcast update status pembayaran realtime ke semua client WebSocket POS
    const updateMessage = JSON.stringify({
        type: "payment_update",
        event: eventName,
        reference,
        external_id: externalId,
        status,
        timestamp: new Date().toISOString(),
    });

    for (const client of clients) {
        if (client.readyState === 1) {
            client.send(updateMessage);
        }
    }

    // Respon sukses HTTP 200 ke MiomiPay
    return res.status(200).json({ received: true });
});

// REST API bawaan
app.get("/api/data", (req, res) => {
    res.json(
        history.at(-1) ?? {
            counter: 0,
            value: 0,
            timestamp: new Date().toISOString(),
        }
    );
});

app.post("/api/message", (req, res) => {
    res.json({
        received: true,
        message: req.body.message ?? "",
        timestamp: new Date().toISOString(),
    });
});

// WebSocket Server
wss.on("connection", (socket) => {
    clients.add(socket);

    socket.on("message", (message) => {
        try {
            const parsed = JSON.parse(message.toString());
            // Tangani event custom jika ada
            if (parsed.type === "subscribe_order") {
                socket.orderCode = parsed.code;
            }
        } catch (_) {}

        const reply = JSON.stringify({
            type: "echo",
            message: message.toString(),
            timestamp: new Date().toISOString(),
        });

        if (socket.readyState === 1) {
            socket.send(reply);
        }
    });

    socket.on("close", () => clients.delete(socket));
});

server.listen(3000, "0.0.0.0", () => {
    console.log("-------------------------------------------------------");
    console.log("Server POS Realtime & MiomiPay Gateway berjalan di port 3000");
    console.log("Endpoint Tagihan: POST http://localhost:3000/api/payment/create");
    console.log("Endpoint Webhook: POST http://localhost:3000/api/payment/webhook");
    console.log("-------------------------------------------------------");
});
