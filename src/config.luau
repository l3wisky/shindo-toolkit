--!strict

return {
    version = "1.0.1",
    repositoryUrl = "https://github.com/l3wisky/shindo-toolkit",
    releaseArtifactUrl = "https://github.com/l3wisky/shindo-toolkit/releases/latest/download/shindo-toolkit.luau",
    rayfield = {
        version = "1.1.0",
        url = "https://github.com/SiriusSoftwareLtd/rayfield-gen2/releases/download/1.1.0/bundled.luau",
        sha256 = "e3c337e969e6c4c0de91a77156201094568be55fdfe2669368c48c1d8169d0a6",
    },
    timeouts = {
        dateConfirmation = 10,
        datePollInterval = 0.08,
    },
    game = {
        homePlaceId = 5451410109,
        rollbackBand = string.char(128),
    },
    icons = {
        kg = "rbxassetid://114333260665056",
        rcgenkai = "rbxassetid://120297133638032",
        misc = "rbxassetid://104136394856650",
        github = "rbxassetid://80397494665808",
    },
    themes = {
        { id = "default", labelKey = "theme_default" },
        { id = "cobalt", labelKey = "theme_cobalt" },
        { id = "ember", labelKey = "theme_ember" },
        { id = "amethyst", labelKey = "theme_amethyst" },
        { id = "frost", labelKey = "theme_frost" },
        { id = "rose", labelKey = "theme_rose" },
    },
}
