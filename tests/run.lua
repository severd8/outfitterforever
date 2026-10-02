-- Runs Outfitter Forever against the fake WoW: Forever client.
--   lua5.1 tests/run.lua            (from the repo root)
-- Forever's LE_EXPANSION_LEVEL_CURRENT isn't known, so everything runs as if it
-- reports the original game (0) and as Midnight (11). And the client's project
-- ID changed during the beta: it reported Mainline's (1) until build 70170, and
-- its own (WOW_PROJECT_CAMELOT, 18) since. Both must work.

local failures = 0
for _, projectId in ipairs({ 18, 1 }) do
	for _, expansionLevel in ipairs({ 0, 11 }) do
		local runner = assert(loadfile("tests/run_tests.lua"))
		local ok, result = pcall(runner, expansionLevel, projectId)
		if not ok then
			print("Test run crashed (expansion level " .. expansionLevel .. ", project " .. projectId .. "): " .. tostring(result))
			failures = failures + 1
		else
			failures = failures + result
		end
	end
end
if failures > 0 then
	print(failures .. " failure(s)")
	os.exit(1)
end
print("All tests passed")
