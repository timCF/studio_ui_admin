module.exports = (state, utils) ->
	jqcb = (e) ->
		keyCode = e.keyCode || e.which
		if ( keyCode ==  13 )
			e.preventDefault()
			nextElement = $('[tabindex="' + (this.tabIndex+1)  + '"]')
			if(nextElement.length != 0)
				nextElement.focus()
			else
				$('.submitmegaform')[0].click()
	$(document).on("keypress",".megaform", jqcb)
	# request template
	req = new utils.proto.Request
	req.cmd = 'CMD_get_state'
	req.client_kind = 'CK_admin'
	req.login = utils.maybe_from_store("login",'')
	req.password = utils.maybe_from_store("password",'')
	req.subject = new utils.proto.FullState
	req.subject.hash = ''
	state.request_template = req
	if ((req.login != '') and (req.password != '')) then utils.CMD_get_state(state)
	utils.state_coroutine(state)
	utils.render()
	if not(state.response_state) then $('[tabindex="' + 1  + '"]').focus()
