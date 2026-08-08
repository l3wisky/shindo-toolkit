local config = require("../src/config")

print(table.concat({
    config.version,
    config.rayfield.version,
    config.rayfield.url,
    config.rayfield.sha256,
    config.releaseArtifactUrl,
}, "\t"))
