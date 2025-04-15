include("libs/global")
include("libs/common")

const ID_GET_LINES = "get_lines"

class get_lines_cmd {
	wts = [
		["road", wt_road],
		["rail", wt_rail],
		["water", wt_water],
		["monorail", wt_monorail],
		["maglev", wt_maglev],
		["tram", wt_tram],
		["narrowgauge", wt_narrowgauge],
		["air", wt_air]
	]

	function get_waytype(param) {
		local wt = filter(wts, (@(wt) wt[0] == param))
		return wt.len() > 0 ? wt[0][1] : null
	}

	function exec(param) {
		local player = null
		local result = {}
		result["command"] <- ID_GET_LINES
		result["id"] <- param["id"]
		try {
			player = player_x(param["player_index"])
		} catch(err) {
			result["error"] <- 1 // Player not found error
			return result
		}

		result["result"] <- []
		local waytype = get_waytype(param["way_type"])
		local LINE_CNT = filter(player.get_line_list(), (@(l) l.is_valid())).len()

		// Since the line ID cannot be obtained from line_x, we iterate ids
		// unless all player's lines are added.
		local cnt = 0
		for (local i = 0; cnt < LINE_CNT; i++) {
			local line = line_x(i)
			if (!line.is_valid() || line.get_owner().get_name() != player.get_name()) {
				continue
			}
			if (waytype == null || line.get_waytype() == waytype) {
				result["result"].append({
					id = i
					name = line.get_name()
				})
			}
			cnt += 1
		}
		return result
	}
}

commands[ID_GET_LINES] <- get_lines_cmd()
