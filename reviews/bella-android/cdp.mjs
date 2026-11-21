// Usage: node cdp.mjs <page-id> '<js expression>'
const [id, expr] = process.argv.slice(2);
const ws = new WebSocket(`ws://localhost:9222/devtools/page/${id}`);
ws.onopen = () => ws.send(JSON.stringify({ id: 1, method: "Runtime.evaluate", params: { expression: expr, returnByValue: true, awaitPromise: true } }));
ws.onmessage = (m) => { const r = JSON.parse(m.data); if (r.id === 1) { console.log(JSON.stringify(r.result?.result?.value ?? r)); ws.close(); } };
