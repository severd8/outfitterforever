-- Runs Outfitter Forever against the fake WoW: Forever client.
--   lua5.1 tests/run.lua            (from the repo root)
-- Forever's LE_EXPANSION_LEVEL_CURRENT isn't known, so everything runs twice:
-- once as if it reports the original game (0) and once as Midnight (11).

local failures = 0
for _, expansionLevel in ipairs({ 0, 11 }) do
	local runner = assert(loadfile("tests/run_tests.lua"))
	local ok, result = pcall(runner, expansionLevel)
	if not ok then
		print("Test run crashed (expansion level " .. expansionLevel .. "): " .. tostring(result))
		failures = failures + 1
	else
		failures = failures + result
	end
end
if failures > 0 then
	print(failures .. " failure(s)")
	os.exit(1)
end
print("All tests passed")
