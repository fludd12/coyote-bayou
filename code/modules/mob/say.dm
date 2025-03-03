//Speech verbs.
// the _keybind verbs uses "as text" versus "as text|null" to force a popup when pressed by a keybind.
/mob/verb/say_typing_indicator()
	set name = "say_indicator"
	set hidden = TRUE
	set category = "IC"
	display_typing_indicator()
	var/message = input(usr, EMOTE_HEADER_TEXT, "say") as text|null
	// If they don't type anything just drop the message.
	clear_typing_indicator()
	if(!length(message))
		return
	if(!findtext(message, "*"))		//this is used to abort the play_AC_typing_indicator() in case someone is using an emote.
		INVOKE_ASYNC(src, .proc/play_AC_typing_indicator, LAZYLEN(message))
	return say_verb(message)

// /mob/verb/play_sound_typing_indicator()
//	play_AC_typing_indicator(GLOB.message_length)

/mob/verb/say_verb(message as text)
	set name = "say"
	set category = "IC"
	if(!length(message))
		return
	if(GLOB.say_disabled)
		to_chat(usr, span_danger("Speech is currently admin-disabled."))
		return
	clear_typing_indicator()
	if(!findtext(message, "*"))		//this is used to abort the play_AC_typing_indicator() in case someone is using an emote.
		INVOKE_ASYNC(src, .proc/play_AC_typing_indicator, LAZYLEN(message))
	say(message)

/mob/verb/me_typing_indicator()
	set name = "me_indicator"
	set hidden = TRUE
	set category = "IC"
	display_typing_indicator()
	var/message = stripped_multiline_input_or_reflect(usr, EMOTE_HEADER_TEXT, "me")
	// If they don't type anything just drop the message.
	clear_typing_indicator()
	if(GLOB.say_disabled)
		to_chat(usr, span_danger("Speech is currently admin-disabled."))
		return
	if(!length(message))
		return
	usr.emote("me",1,message,TRUE)

/mob/verb/me_verb(message as message)
	set name = "me"
	set category = "IC"
	if(!length(message))
		return
	if(GLOB.say_disabled)
		to_chat(usr, span_danger("Speech is currently admin-disabled."))
		return
	
	if(length(message) > MAX_MESSAGE_LEN)
		to_chat(usr, message)
		to_chat(usr, span_danger("^^^----- The preceeding message has been DISCARDED for being over the maximum length of [MAX_MESSAGE_LEN]. It has NOT been sent! -----^^^"))
		return

	message = trim(copytext_char(sanitize(message), 1, MAX_MESSAGE_LEN))
	clear_typing_indicator()		// clear it immediately!

	usr.emote("me",1,message,TRUE)

/**
 * Ensure that the first word of a sentence gets transformed into lower case
 * e.g. `Nods her head and stares at McMullen` becomes
 * `nods her head and stares at McMullen`.
 */
/proc/lowertext_first_word(sentence)
	var/list/words_in_sentence = splittext(sentence, regex(@"[ ]+"))
	var/treated_sentence = ""
	var/sentence_len = length(words_in_sentence)
	if(sentence_len == 0)
		return sentence
	var/i = 0
	for(var/word_in_sentence in words_in_sentence)
		treated_sentence += i == 0 ? lowertext(word_in_sentence) : word_in_sentence
		if (i != sentence_len - 1)
			treated_sentence += " "
		i += 1
	return treated_sentence

/mob/say_mod(input, message_mode)
	if((input[1] == "!") && (length_char(input) > 1))
		message_mode = MODE_CUSTOM_SAY
		return copytext_char(input, 2)
	var/customsayverb = findtext(input, "*")
	if(customsayverb)
		message_mode = MODE_CUSTOM_SAY
		return lowertext_first_word(copytext_char(input, 1, customsayverb))
	return ..()

/proc/uncostumize_say(input, message_mode)
	. = input
	if(message_mode == MODE_CUSTOM_SAY)
		var/customsayverb = findtext(input, "*")
		return lowertext(copytext_char(input, 1, customsayverb))

/mob/proc/whisper_keybind()
	var/message = input(src, "", "whisper") as text|null
	if(!length(message))
		return
	return whisper_verb(message)

/mob/verb/whisper_verb(message as text)
	set name = "Whisper"
	set category = "IC"
	if(!length(message))
		return
	if(GLOB.say_disabled)	//This is here to try to identify lag problems
		to_chat(usr, span_danger("Speech is currently admin-disabled."))
		return
	whisper(message)

/mob/proc/whisper(message, datum/language/language=null)
	say(message, language) //only living mobs actually whisper, everything else just talks

/mob/proc/say_dead(message)
	var/name = real_name
	var/alt_name = ""

	if(GLOB.say_disabled)	//This is here to try to identify lag problems
		to_chat(usr, span_danger("Speech is currently admin-disabled."))
		return

	var/jb = jobban_isbanned(src, "OOC")
	if(QDELETED(src))
		return

	if(jb)
		to_chat(src, span_danger("You have been banned from deadchat."))
		return



	if (src.client)
		if(src.client.prefs.muted & MUTE_DEADCHAT)
			to_chat(src, span_danger("You cannot talk in deadchat (muted)."))
			return

		if(src.client.handle_spam_prevention(message,MUTE_DEADCHAT))
			return

	var/mob/dead/observer/O = src
	if(isobserver(src) && O.deadchat_name)
		name = "[O.deadchat_name]"
	else
		if(mind && mind.name)
			name = "[mind.name]"
		else
			name = real_name
		if(name != real_name)
			alt_name = " (died as [real_name])"

	var/spanned = say_quote(say_emphasis(message))
	message = emoji_parse(message)
	var/rendered = "<span class='game deadsay'><span class='prefix'>DEAD:</span> <span class='name'>[name]</span>[alt_name] <span class='message'>[emoji_parse(spanned)]</span></span>"
	log_talk(message, LOG_SAY, tag="DEAD")
	deadchat_broadcast(rendered, follow_target = src, speaker_key = key)

/mob/proc/check_emote(message, just_runechat = FALSE)
	if(message[1] == "*")
		emote(copytext(message, length(message[1]) + 1), intentional = TRUE, only_overhead = just_runechat)
		return TRUE

/mob/proc/hivecheck()
	return 0

/mob/proc/lingcheck()
	return LINGHIVE_NONE

/mob/proc/get_message_mode(message)
	var/key = message[1]
	if(key == "#")
		return MODE_WHISPER
	else if(key == "%")
		return MODE_SING
	else if(key == ";")
		return MODE_HEADSET
	else if((length(message) > (length(key) + 1)) && (key in GLOB.department_radio_prefixes))
		var/key_symbol = lowertext(message[length(key) + 1])
		return GLOB.department_radio_keys[key_symbol]
