module.exports = (state, utils) ->
	# request template
	req = new utils.proto.Request
	req.cmd = 'CMD_get_state'
	req.client_kind = 'CK_admin'
	req.login = ''
	req.password = ''
	state.request_template = req
