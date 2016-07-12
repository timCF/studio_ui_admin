module.exports = (state, utils) ->
	jqcb = (e) ->
		keyCode = e.keyCode || e.which
		if ( keyCode ==  13 )
			e.preventDefault()
			nextElement = $('[tabindex="' + (this.tabIndex+1)  + '"]')
			if(nextElement.length != 0)
				nextElement.focus()
			else
				$('[tabindex="1"]').focus()
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
