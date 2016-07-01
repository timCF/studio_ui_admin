module.exports = (state, utils) ->
	# request template
	req = new utils.proto.Request
	req.cmd = 'CMD_get_state'
	req.client_kind = 'CK_admin'
	req.login = utils.maybe_from_store("login",'')
	req.password = utils.maybe_from_store("password",'')
	state.request_template = req
	if ((req.login != '') and (req.password != '')) then utils.CMD_get_state(state)
