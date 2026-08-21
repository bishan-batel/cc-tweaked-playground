import { WebSocketServer } from "ws";
import fs from "fs";
import path from "path";
import chokidar from "chokidar";

const wss = new WebSocketServer({ port: 8080 });

const SOURCE_DIRECTORY = path.resolve("./src/");

function* readAllFiles(dir: string): Generator<string> {
  const files = fs.readdirSync(dir, { withFileTypes: true });

  for (const file of files) {
    if (file.isDirectory()) {
      yield* readAllFiles(path.join(dir, file.name));
    } else {
      yield path.join(dir, file.name);
    }
  }
}

const formatMessage = (filePath: string) => {
  const relative = filePath;

  filePath = path.join(SOURCE_DIRECTORY, filePath);

  const stats = fs.lstatSync(filePath);

  if (stats.isFile()) {
    return relative + "@" + fs.readFileSync(filePath, "utf8");
  }

  return null;
};



wss.on("connection", (ws) => {
  console.log("ComputerCraft connected!");

  for (const fp of readAllFiles(SOURCE_DIRECTORY)) {
    const message = formatMessage(path.relative(SOURCE_DIRECTORY, fp));
    if (message) {
      ws.send(message);
    }
  }

  const watcher = chokidar.watch(SOURCE_DIRECTORY, {
    ignored: (path, stats) => !!stats?.isFile() && !path.endsWith(".lua"),
    persistent: true,
  });

  watcher.on("change", (filePath) => {
    filePath = path.relative(SOURCE_DIRECTORY, filePath)
    console.log(`File updated (${filePath}). Sending to game...`);
    const message = formatMessage(filePath);
    if (message) ws.send(message);
  });

  ws.on("close", () => watcher.close());
});

console.log("WS Server running on port 8080");
