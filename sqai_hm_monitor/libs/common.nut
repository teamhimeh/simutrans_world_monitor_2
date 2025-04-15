function get_player_list() {
    local pl_list = []
    for (local i=0; i<20; i++) {
        local pl = player_x(i)
        if(pl.is_valid()) {
            pl_list.append(pl)
        }
    }
    return pl_list
}

function _step_generator(iteratable) {
    foreach (obj in iteratable) {
        yield obj
    }
}

function filter(array, func) {
    local new_array = []
    foreach (obj in _step_generator(array)) {
        if(func(obj)) {
            new_array.append(obj)
        }
    }
    return new_array
}

function map(array, func) {
    local new_array = []
    foreach (obj in _step_generator(array)) {
        new_array.append(func(obj))
    }
    return new_array
}
