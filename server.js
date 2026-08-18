const WebSocket = require("ws");
const fs = require("fs");
const chokidar = require("chokidar");

const wss = new WebSocket.Server({ port: 8080 });
const FILE_PATH = "./program.lua";

if (!fs.existsSync(FILE_PATH)) {
  fs.writeFileSync(FILE_PATH, "-- Write code here");
}

wss.on("connection", (ws) => {
  console.log("ComputerCraft connected!");

  // Send current code immediately on connect
  ws.send(fs.readFileSync(FILE_PATH, "utf8"));

  // Watch for file saves and push updates live
  const watcher = chokidar.watch(FILE_PATH).on("change", () => {
    console.log("File updated. Sending to game...");
    ws.send(fs.readFileSync(FILE_PATH, "utf8"));
  });

  ws.on("close", () => watcher.close());
});

console.log("WS Server running on port 8080");
