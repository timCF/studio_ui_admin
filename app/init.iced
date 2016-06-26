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
		datepair: false,
		datepairval: {
			date: {start: '', end: ''},
			time: {start: '', end: ''}
		}
	}
	# some compile-time defined utils, frozen
	utils = Object.freeze(tmp = require("utils") ; tmp.proto = require("protobufjs").loadProtoFile("./studio_proto/studio.proto").build("lemooor.studio") ; tmp)
	console.log(utils.proto)
	# full state structure, frozen
	fullstate = Object.freeze({state: state, utils: utils})
	react = require("react-dom")
	widget = require("widget")
	render = () ->
		datepair = document.getElementById('datepair')
		if not(datepair) then (state.datepair = false)
		if not(state.datepair) and datepair
			$('#datepair .time').timepicker(timepicker_opts)
			$('#datepair .date').datepicker(datepicker_opts)
			state.datepair = new Datepair(datepair, {defaultTimeDelta: 10800000})
			$('#datepair').on('rangeSelected', () ->
				state.datepairval.date.start = $('#datepair .date.start').datepicker('getDate')
				state.datepairval.date.end = $('#datepair .date.end').datepicker('getDate')
				state.datepairval.time.start = $('#datepair .time.start').timepicker('getTime')
				state.datepairval.time.end = $('#datepair .time.end').timepicker('getTime')
				#
				#	TODO : set value of view render !!!
				#
				console.log state.datepairval
			)
			console.log("init datetime picker")
		react.render(widget(fullstate), document.getElementById("main_frame"))
	setInterval(render, 500)
	require("main")(state, utils)
