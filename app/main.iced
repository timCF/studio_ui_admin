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
	post_render = () ->
		Logger.debug("post_render page")
		await utils.render(defer dummy)
		Logger.debug("post_render events")
		utils.rerender_events_coroutine_process(null)
		Logger.debug("post_render finished")
	window.onclick = () ->
		state.last_click = moment()
		if not(state.is_focused) then window.onfocus()
	window.onfocus = () ->
		console.log("window focused")
		state.last_click = moment()
		state.is_focused = true
		post_render()
	window.onblur = () ->
		console.log("window UNfocused")
		state.is_focused = false
		post_render()
	Logger.useDefaults({formatter: (messages, context) -> messages.unshift(moment().format('YYYY-MM-DD HH:mm:ss'))})
