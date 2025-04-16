include("libs/JSONEncoder.class")
include("libs/JSONParser.class")
include("libs/global")
include("libs/get_players")
include("libs/get_lines")

function start(pl_num) {

}

function resume_game(pl_num) {
    // monitoring_state().load()
}

// リクエストが実行されたときにはtrueを返す．
function process_request() {
    local f = file(path_cmd,"r")
    if(f==null) {
        return false
    }
    f = file(path_cmd,"r")
    local str = f.readstr(10000)
    f.close()
    if(str.len()==0) {
        return false
    }
    local decoded_command = JSONParser().parse(str)
    local cmd_id = decoded_command["command"]
    //コマンドがあれば実行する．
    local response = {}
    if(cmd_id in commands) {
        response =  commands[cmd_id].exec(decoded_command)
    } else {
        response["command"] <- "error"
        response["id"] <- decoded_command["id"]
        response["description"] <- "command " + cmd_id + " not found"
    }
    f = file(path_output,"w")
    f.writestr(JSONEncoder.encode(response))
    f.close()
    f = file(path_cmd,"w")
    f.writestr("")
    f.close()
    return true
}

function step() {
     if(process_request()) {
         return
     }
//    foreach (m in monitored) {
//      if(m.check()) {
//        // 負荷軽減のため，モニタリングタスクは1つのみ実行．
//        return
//      }
//    }
}

function new_month() {

}

commands[ID_GET_LINES] <- get_lines_cmd()
commands[ID_GET_PLAYER_LIST] <- get_players_cmd()