GLOBAL_LIST_EMPTY(virology_goals)

/datum/virology_goal
	var/name = "Generic Virology Goal"
	var/delivered_amount = 0
	var/delivery_goal = 15
	var/completed = FALSE

/datum/virology_goal/proc/get_report()
	return "Complete this goal."

/datum/virology_goal/proc/get_ui_report()
	return "Complete this goal."

/datum/virology_goal/proc/check_completion(list/datum/reagent/reagent_list)
	return TRUE

/datum/virology_goal/Destroy()
	LAZYREMOVE(GLOB.virology_goals, src)
	. = ..()

/datum/virology_goal/Topic(href, href_list)
	..()

	if(!check_rights(R_EVENT))
		return

	if(href_list["remove"])
		qdel(src)

/datum/virology_goal/propertysymptom
	name = "Symptom With Properties Viral Sample Request"
	var/goal_symptom //Type path of the symptom
	var/goal_symptom_name
	var/goal_property
	var/goal_property_text
	var/goal_property_value

/datum/virology_goal/propertysymptom/New()
	var/type = pick(subtypesof(/datum/symptom))
	var/datum/symptom/S = new type()
	goal_symptom = S.type
	goal_symptom_name = S.name
	goal_property = pick("resistance", "stealth", "stage_rate", "transmittable")
	if(goal_property == "stage_rate")
		goal_property_text = "stage rate"
	else
		goal_property_text = goal_property
	goal_property_value = rand(-18 , 11)
	switch(goal_property)
		if("resistance")
			goal_property_value += S.resistance
		if("stealth")
			goal_property_value += S.stealth
		if("stage_rate")
			goal_property_value += S.stage_speed
		if("transmittable")
			goal_property_value += S.transmittable
	qdel(S)

/datum/virology_goal/propertysymptom/get_report()
	return {"<b>Effects of [goal_symptom_name] symptom and level [goal_property_value] [goal_property_text]</b><br>
	Viral samples with a specific symptom and properties are required to study the effects of this symptom in various conditions. We need you to deliver [delivery_goal]u of viral samples containing the [goal_symptom_name] symptom and with the [goal_property_text] property at level [goal_property_value] along with 3 other symptoms to us through the cargo shuttle.
	<br>
	-Nanotrasen Virology Research"}

/datum/virology_goal/propertysymptom/get_ui_report()
	return {"Viral samples with a specific symptom and properties are required to study the effects of this symptom in various conditions. We need you to deliver [delivery_goal]u of viral samples containing the [goal_symptom_name] symptom and with the [goal_property_text] property at level [goal_property_value] along with 3 other symptoms to us through the cargo shuttle."}

/datum/virology_goal/propertysymptom/check_completion(list/datum/reagent/reagent_list)
	. = FALSE
	var/datum/reagent/blood/BL = locate() in reagent_list
	if(BL && BL.data && BL.data["viruses"])
		for(var/datum/disease/advance/D in BL.data["viruses"])
			if(length(D.symptoms) < 4) //We want 3 other symptoms alongside the requested one
				continue
			var/properties = D.GenerateProperties()
			var/property = properties[goal_property]
			if(!(property == goal_property_value))
				continue
			for(var/datum/symptom/S in D.symptoms)
				if(!goal_symptom)
					return
				if(S.type == goal_symptom)
					delivered_amount += BL.volume
					if(delivered_amount >= delivery_goal)
						delivered_amount = delivery_goal
						completed = TRUE
						return TRUE
				else
					continue

/datum/virology_goal/virus
	name = "Specific Viral Sample Request (Non-Stealth)"
	var/list/goal_symptoms = list() //List of type paths of the symptoms, we could go with a diseaseID here instead a list of symptoms but we need the list to tell the player what symptoms to include

/datum/virology_goal/virus/New()
	var/list/datum/symptom/symptoms = subtypesof(/datum/symptom)
	var/stealth = 0
	for(var/i in 1 to 5)
		var/list/datum/symptom/candidates = list()
		for(var/V in symptoms) //I have no idea why a normal for loop of "for(var/datum/symptom/V in symptoms)" doesnt work here but iam not gonna try and fix it, because i was stuck at this bug for weeks already
			var/datum/symptom/S = V
			if(stealth + S.stealth >= 3) //The Pandemic cant detect a virus with stealth 3 or higher and we dont want that, this isnt a stealth virus
				continue
			candidates += S
		var/datum/symptom/S2 = pick(candidates)
		goal_symptoms += S2
		stealth += S2.stealth
		symptoms -= S2


/datum/virology_goal/virus/get_report()
	return {"<b>Specific Viral Sample Request (Non-Stealth)</b><br>
	A specific viral sample is required for confidential reasons. We need you to deliver [delivery_goal]u of viral samples with exactly only the following symptoms: [symptoms_list2text()] to us through the cargo shuttle.
	<br>
	-Nanotrasen Virology Research"}

/datum/virology_goal/virus/get_ui_report()
	return {"A specific viral sample is required for confidential reasons. We need you to deliver [delivery_goal]u of viral samples with exactly only the following symptoms: [symptoms_list2text()] to us through the cargo shuttle."}

/datum/virology_goal/virus/proc/symptoms_list2text()
	var/list/msg = list()
	for(var/S in goal_symptoms)
		var/datum/symptom/SY = new S()
		msg += "[SY]"
		qdel(SY)
	return jointext(msg, ", ")

/datum/virology_goal/virus/check_completion(list/datum/reagent/reagent_list)
	. = FALSE
	var/datum/reagent/blood/BL = locate() in reagent_list
	if(BL && BL.data && BL.data["viruses"])
		for(var/datum/disease/advance/D in BL.data["viruses"])
			if(length(D.symptoms) != length(goal_symptoms)) //This is here so viruses with extra symptoms dont get approved
				return
			var/skip = FALSE
			for(var/S in goal_symptoms)
				var/datum/symptom/SY = locate(S) in D.symptoms
				if(!SY)
					skip = TRUE
					break
			if(!skip)
				delivered_amount += BL.volume
				if(delivered_amount >= delivery_goal)
					delivered_amount = delivery_goal
					completed = TRUE
					return TRUE

/datum/virology_goal/virus/stealth
	name = "Specific Viral Sample Request (Stealth)"

/datum/virology_goal/virus/stealth/New()
	var/list/datum/symptom/symptoms = subtypesof(/datum/symptom)
	var/stealth = 0
	for(var/i in 1 to 5)
		var/list/datum/symptom/candidates = list()
		for(var/V in symptoms) //I have no idea why a normal for loop of "for(var/datum/symptom/V in symptoms)" doesnt work here but iam not gonna try and fix it, because i was stuck at this bug for weeks already
			var/datum/symptom/S = V
			if(stealth + S.stealth < 3) //The Pandemic cant detect a virus with stealth 3 or higher and we want that, this is a stealth virus
				continue
			candidates += S
		var/datum/symptom/S2 = pick(candidates)
		goal_symptoms += S2
		stealth += S2.stealth
		symptoms -= S2

/datum/virology_goal/virus/stealth/get_report()
	return {"<b>Specific Viral Sample Request (Stealth)</b><br>
	A specific viral sample is required for confidential reasons. We need you to deliver [delivery_goal]u of viral samples with exactly only the following symptoms: [symptoms_list2text()] to us through the cargo shuttle.
	<br>
	-Nanotrasen Virology Research"}