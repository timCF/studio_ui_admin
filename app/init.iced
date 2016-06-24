document.addEventListener "DOMContentLoaded", (e) ->
	timepicker_opts = {
		minTime: "9:00"
		timeFormat: 'H:i',
		disableTextInput: true,
		disableTouchKeyboard: true,
		show2400: true,
		step: 15
	}
	datepicker_opts = {
		format: 'dd/mm/yyyy',
		autoclose: true,
		daysOfWeekHighlighted: '06',
		disableTouchKeyboard: true,
		todayBtn: true,
		todayHighlight: true,
		weekStart: 1,
	}
	# state for main function, mutable
	state = {
		opts: {},
		data: {},
		datepair: false
	}
	# some compile-time defined utils, frozen
	utils = Object.freeze(require("utils"))
	# full state structure, frozen
	fullstate = Object.freeze({state: state, utils: utils})
	react = require("react-dom")
	widget = require("widget")
	render = () ->
		if not(state.datepair)
			datepair = document.getElementById('datepair')
			if datepair
					$('#datepair .time').timepicker(timepicker_opts)
					$('#datepair .date').datepicker(datepicker_opts)
					state.datepair = new Datepair(datepair, {defaultTimeDelta: 10800000})
					console.log("init datetime picker")
		console.log(state.datepair)
		react.render(widget(fullstate), document.getElementById("main_frame"))
	setInterval(render, 500)
	require("main")(state, utils)
