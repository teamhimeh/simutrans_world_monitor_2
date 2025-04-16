class get_players_cmd {
	// プレイヤーの一覧を返す
	function exec(param) {
        local result = {}
        result["command"] <- ID_GET_PLAYER_LIST
        result["id"] <- param["id"]
        local players = []
        for (local i = 0; i < 20; i++) {
            local pl = player_x(i)
            if (pl.is_valid()) {
                local player_desc = {}
                player_desc["index"] <- i
                player_desc["name"] <- pl.get_name()
                players.append(player_desc)
            }
        }
        result["result"] <- players
        return result
	}
}
