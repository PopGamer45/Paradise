/*

	Advance Disease is a system for Virologist to Engineer their own disease with symptoms that have effects and properties
	which add onto the overall disease.

	If you need help with creating new symptoms or expanding the advance disease, ask for Giacom on #coderbus.

*/
GLOBAL_LIST_EMPTY(archive_diseases)

// The order goes from easy to cure to hard to cure.
GLOBAL_LIST_INIT(resistance1_cures, list("sodiumchloride", "sugar", "orangejuice"))
GLOBAL_LIST_INIT(resistance2_cures, list("spaceacillin", "salglu_solution", "ethanol", "mutagen"))
GLOBAL_LIST_INIT(resistance3_cures, list("applejack", "syndicatebomb", "space_drugs"))
GLOBAL_LIST_INIT(resistance4_cures, list("msg", "omnizine", "changelingsting"))
GLOBAL_LIST_INIT(resistance5_cures, list("ether", "kelotane", "synthflesh"))
GLOBAL_LIST_INIT(resistance6_cures, list("nothing", "jenkem", "fishwater"))
GLOBAL_LIST_INIT(resistance7_cures, list("lsd", "liquid_solder", "capulettium"))
GLOBAL_LIST_INIT(resistance8_cures, list("cleaner", "acetaldehyde", "antihol"))
GLOBAL_LIST_INIT(resistance8B_cures, list("triple_citrus", "atrazine", "space_drugs"))
GLOBAL_LIST_INIT(resistance9_cures, list("capulettium", "acetic_acid", "sodiumchloride"))
GLOBAL_LIST_INIT(resistance9B_cures, list("sodiumchloride", "sodiumchloride", "sodiumchloride"))
GLOBAL_LIST_INIT(resistance10_cures, list("cyanide", "sulfonal", "sodiumchloride"))
GLOBAL_LIST_INIT(resistance10B_cures, list("sodiumchloride", "sodiumchloride", "sodiumchloride"))
GLOBAL_LIST_INIT(resistance11_cures, list("lazarus_reagent", "sulfonal", "sodiumchloride"))
GLOBAL_LIST_INIT(resistance11B_cures, list("cyanide", "sodiumchloride", "sodiumchloride"))
GLOBAL_LIST(advance_cures)

/*

	PROPERTIES

 */

/datum/disease/advance

	name = "Unknown" // We will always let our Virologist name our disease.
	desc = "An engineered disease which can contain a multitude of symptoms."
	form = "Advance Disease" // Will let med-scanners know that this disease was engineered.
	agent = "advance microbes"
	max_stages = 5
	spread_text = "Unknown"
	viable_mobtypes = list(/mob/living/carbon/human)

	// NEW VARS

	var/list/symptoms = list() // The symptoms of the disease.
	var/id = ""
	var/processing = FALSE
	var/mutated = FALSE
	var/can_mutate = TRUE
	var/mutate_cooldown = 75 SECONDS
	var/last_mutate
	var/mutation_generation = 0 //Order of this disease in a "mutation tree chart"
	var/datum/disease/parent_mutation //The disease that this disease was mutated from

/*

	OLD PROCS

 */

/datum/disease/advance/New(process = 1, datum/disease/advance/D)
	if(!istype(D))
		D = null
	// Generate symptoms if we weren't given any.

	if(!symptoms || !symptoms.len)

		if(!D || !D.symptoms || !D.symptoms.len)
			symptoms = GenerateSymptoms(0, 2)
		else
			var/list/skipped = list("type","parent_type","vars","transformed")
			for(var/V in D.vars)
				if(V in skipped)
					continue
				if(istype(D.vars[V],/list))
					var/list/L = D.vars[V]
					vars[V] = L.Copy()
				else
					vars[V] = D.vars[V]

	if(!GLOB.advance_cures)
		GLOB.advance_cures = list()
		var/resistance_levels = 11
		GLOB.advance_cures.len = resistance_levels
		for(var/i=1,i<=resistance_levels,i++)
			GLOB.advance_cures[i] = list()
		GLOB.advance_cures[1] += GLOB.resistance1_cures[rand(1, GLOB.resistance1_cures.len)]
		GLOB.advance_cures[2] += GLOB.resistance2_cures[rand(1, GLOB.resistance2_cures.len)]
		GLOB.advance_cures[3] += GLOB.resistance3_cures[rand(1, GLOB.resistance3_cures.len)]
		GLOB.advance_cures[4] += GLOB.resistance4_cures[rand(1, GLOB.resistance4_cures.len)]
		GLOB.advance_cures[5] += GLOB.resistance5_cures[rand(1, GLOB.resistance5_cures.len)]
		GLOB.advance_cures[6] += GLOB.resistance6_cures[rand(1, GLOB.resistance6_cures.len)]
		GLOB.advance_cures[7] += GLOB.resistance7_cures[rand(1, GLOB.resistance7_cures.len)]
		GLOB.advance_cures[8] += GLOB.resistance8_cures[rand(1, GLOB.resistance8_cures.len)] += GLOB.resistance8B_cures[rand(1, GLOB.resistance8B_cures.len)]
		GLOB.advance_cures[9] += GLOB.resistance9_cures[rand(1, GLOB.resistance9_cures.len)] += GLOB.resistance9B_cures[rand(1, GLOB.resistance9B_cures.len)]
		GLOB.advance_cures[10] += GLOB.resistance10_cures[rand(1, GLOB.resistance10_cures.len)] += GLOB.resistance10B_cures[rand(1, GLOB.resistance10B_cures.len)]
		GLOB.advance_cures[11] += GLOB.resistance11_cures[rand(1, GLOB.resistance11_cures.len)] += GLOB.resistance11B_cures[rand(1, GLOB.resistance11B_cures.len)]

	Refresh()
	..(process, D)
	return

/datum/disease/advance/Destroy()
	if(processing)
		for(var/datum/symptom/S in symptoms)
			S.End(src)
	return ..()

// Randomly pick a symptom to activate.
/datum/disease/advance/stage_act()
	if(!..())
		return FALSE
	if(symptoms && symptoms.len)

		if(!processing)
			processing = TRUE
			for(var/datum/symptom/S in symptoms)
				S.Start(src)

		for(var/datum/symptom/S in symptoms)
			S.Activate(src)

		if(!last_mutate)
			last_mutate = world.time
		if(world.time > last_mutate + mutate_cooldown && prob(3))
			Mutate()
	else
		CRASH("We do not have any symptoms during stage_act()!")
	return TRUE

// Compares type then ID.
/datum/disease/advance/IsSame(datum/disease/advance/D)

	if(!(istype(D, /datum/disease/advance)))
		return 0

	if(GetDiseaseID() != D.GetDiseaseID())
		return 0
	return 1

// To add special resistances.
/datum/disease/advance/cure(resistance = FALSE)
	if(affected_mob)
		var/id = "[GetDiseaseID()]"
		if(resistance && !(id in affected_mob.resistances))
			affected_mob.resistances[id] = id
		affected_mob.antibodies[id] = id
		remove_virus()
	qdel(src)	//delete the datum to stop it processing

// Returns the advance disease with a different reference memory.
/datum/disease/advance/Copy(process = 0)
	return new /datum/disease/advance(process, src, 1)

/*

	NEW PROCS

 */

// Randomly mutates the virus either by adding or replacing symptoms
/datum/disease/advance/proc/Mutate(var/cooldown = TRUE, var/forced = FALSE)
	var/datum/disease/parent = src.Copy()
	var/datum/symptom/old_symptom
	var/datum/symptom/new_symptom
	if(!forced && !can_mutate && !affected_mob.reagents.has_reagent("spaceacillin"))
		return
	if(prob(100/symptoms.len) || symptoms.len == 1)
		new_symptom = GenerateSymptomsBySeverity(1, GetSeverity())[1]
	else
		// Makes the virus unable to mutate one symptom with the highest severity
		var/list/symptoms_pick = symptoms.Copy()
		var/datum/symptom/R
		for(var/datum/symptom/S in symptoms_pick)
			if(!R)
				R = S
				continue
			if(S.severity > R.severity)
				R = S
		symptoms_pick -= R
		old_symptom = pick(symptoms_pick)
		new_symptom = GenerateSymptomsBySeverity(old_symptom.severity, old_symptom.severity + 1)[1]
	var/datum/disease/advance/new_virus = src.Copy()
	if(old_symptom)
		new_virus.RemoveSymptom(old_symptom)
	new_virus.AddSymptom(new_symptom)
	new_virus.id = null
	if(new_virus.GetDiseaseID() in GLOB.archive_diseases)
		return FALSE

	if(old_symptom)
		RemoveSymptom(old_symptom)
	AddSymptom(new_symptom)
	new_symptom.Start(src)
	Refresh(1)
	mutated = TRUE
	mutation_generation += 1
	parent_mutation = parent.Copy()
	if(cooldown)
		last_mutate = world.time

// Gets the distance from this disease to another in the "mutation tree"
/datum/disease/advance/GetMutationDistance(var/datum/disease/advance/D)
	var/datum/disease/advance/disease1 = src
	var/datum/disease/advance/disease2 = D
	var/distance = 0
	if(!IsSameMutationTree(disease2))
		return
	if(disease1.mutation_generation != disease2.mutation_generation)
		if(disease1.mutation_generation > disease2.mutation_generation)
			while(disease1.mutation_generation > disease2.mutation_generation)
				disease1 = disease1.parent_mutation
				distance += 1
		else
			while(disease1.mutation_generation < disease2.mutation_generation)
				disease2 = disease2.parent_mutation
				distance += 1

	while(disease1.GetDiseaseID() != disease2.GetDiseaseID())
		disease1 = disease1.parent_mutation
		disease2 = disease2.parent_mutation
		distance += 2
	return distance

/datum/disease/advance/proc/IsSameMutationTree(var/datum/disease/advance/D)
	var/datum/disease/advance/disease1 = src
	var/datum/disease/advance/disease2 = D
	while(disease1.mutation_generation != 0 || disease2.mutation_generation != 0)
		if(disease1.parent_mutation)
			disease1 = disease1.parent_mutation
		else
		if(disease2.parent_mutation)
			disease2 = disease2.parent_mutation
		else
	if(disease1.GetDiseaseID() == disease2.GetDiseaseID())
		return TRUE
	else
		return FALSE

// Mix the symptoms of two diseases (the src and the argument)
/datum/disease/advance/proc/Mix(datum/disease/advance/D)
	if(!(IsSame(D)))
		var/list/possible_symptoms = shuffle(D.symptoms)
		for(var/datum/symptom/S in possible_symptoms)
			AddSymptom(new S.type)

/datum/disease/advance/proc/HasSymptom(datum/symptom/S)
	for(var/datum/symptom/symp in symptoms)
		if(symp.id == S.id)
			return 1
	return 0

/datum/disease/advance/proc/GenerateSymptomsBySeverity(sev_min, sev_max, amount = 1)

	var/list/generated = list() // Symptoms we generated.

	var/list/possible_symptoms = list()
	for(var/symp in GLOB.list_symptoms)
		var/datum/symptom/S = new symp
		if(S.severity >= sev_min && S.severity <= sev_max)
			if(!HasSymptom(S))
				possible_symptoms += S

	if(!length(possible_symptoms))
		return generated

	for(var/i = 1 to amount)
		generated += pick_n_take(possible_symptoms)

	return generated


// Will generate new unique symptoms, use this if there are none. Returns a list of symptoms that were generated.
/datum/disease/advance/proc/GenerateSymptoms(level_min, level_max, amount_get = 0)

	var/list/generated = list() // Symptoms we generated.

	// Generate symptoms. By default, we only choose non-deadly symptoms.
	var/list/possible_symptoms = list()
	for(var/symp in GLOB.list_symptoms)
		var/datum/symptom/S = new symp
		if(S.level >= level_min && S.level <= level_max)
			if(!HasSymptom(S))
				possible_symptoms += S

	if(!possible_symptoms.len)
		return generated

	// Random chance to get more than one symptom
	var/number_of = amount_get
	if(!amount_get)
		number_of = 1
		while(prob(20))
			number_of += 1

	for(var/i = 1; number_of >= i && possible_symptoms.len; i++)
		generated += pick_n_take(possible_symptoms)

	return generated

/datum/disease/advance/proc/Refresh(new_name = FALSE, archive = FALSE)
	var/list/properties = GenerateProperties()
	AssignProperties(properties)
	id = null

	if(!GLOB.archive_diseases[GetDiseaseID()])
		if(new_name)
			AssignName()
		GLOB.archive_diseases[GetDiseaseID()] = src // So we don't infinite loop
		GLOB.archive_diseases[GetDiseaseID()] = new /datum/disease/advance(0, src, 1)

	var/datum/disease/advance/A = GLOB.archive_diseases[GetDiseaseID()]
	AssignName(A.name)

//Generate disease properties based on the effects. Returns an associated list.
/datum/disease/advance/proc/GenerateProperties()

	if(!symptoms || !symptoms.len)
		CRASH("We did not have any symptoms before generating properties.")

	var/list/properties = list("resistance" = 1, "stealth" = 0, "stage_rate" = 1, "transmittable" = 1, "severity" = 0)

	for(var/datum/symptom/S in symptoms)

		properties["resistance"] += S.resistance
		properties["stealth"] += S.stealth
		properties["stage_rate"] += S.stage_speed
		properties["transmittable"] += S.transmittable
		properties["severity"] = max(properties["severity"], S.severity) // severity is based on the highest severity symptom

	return properties

// Assign the properties that are in the list.
/datum/disease/advance/proc/AssignProperties(list/properties = list())

	if(properties && properties.len)
		switch(properties["stealth"])
			if(2)
				visibility_flags = HIDDEN_SCANNER
			if(3 to INFINITY)
				visibility_flags = HIDDEN_SCANNER|HIDDEN_PANDEMIC

		// The more symptoms we have, the less transmittable it is but some symptoms can make up for it.
		SetSpread(clamp(2 ** (properties["transmittable"] - symptoms.len), BLOOD, AIRBORNE))
		permeability_mod = max(CEILING(0.4 * properties["transmittable"], 1), 1)
		cure_chance = 15 - clamp(properties["resistance"], -5, 5) // can be between 10 and 20
		stage_prob = max(properties["stage_rate"], 2)
		SetSeverity(properties["severity"])
		GenerateCure(properties)
	else
		CRASH("Our properties were empty or null!")


// Assign the spread type and give it the correct description.
/datum/disease/advance/proc/SetSpread(spread_id)
	switch(spread_id)
		if(NON_CONTAGIOUS, SPECIAL)
			spread_text = "Non-contagious"
		if(CONTACT_GENERAL, CONTACT_HANDS, CONTACT_FEET)
			spread_text = "On contact"
		if(AIRBORNE)
			spread_text = "Airborne"
		if(BLOOD)
			spread_text = "Blood"

	spread_flags = spread_id

/datum/disease/advance/proc/SetSeverity(level_sev)

	switch(level_sev)

		if(-INFINITY to 0)
			severity = NONTHREAT
		if(1)
			severity = MINOR
		if(2)
			severity = MEDIUM
		if(3)
			severity = HARMFUL
		if(4)
			severity = DANGEROUS
		if(5 to INFINITY)
			severity = BIOHAZARD
		else
			severity = "Unknown"

/datum/disease/advance/proc/GetSeverity()

	if(severity == NONTHREAT)
		return 0
	if(severity == MINOR)
		return 1
	if(severity == MEDIUM)
		return 2
	if(severity == HARMFUL)
		return 3
	if(severity == DANGEROUS)
		return 4
	if(severity == BIOHAZARD)
		return 5


// Will generate a random cure, the less resistance the symptoms have, the harder the cure.
/datum/disease/advance/proc/GenerateCure(list/properties = list())
	if(properties && properties.len)
		var/res = clamp(properties["resistance"] - (symptoms.len / 2), 1, GLOB.advance_cures.len)
//		to_chat(world, "Res = [res]")
		cures = GLOB.advance_cures[res]
		var/list/cure_names = list()
		cure_names.len = cures.len
		var/i = 0
		for(var/N in cures)
			i++
			var/datum/reagent/C = GLOB.chemical_reagents_list[cures[i]]
			cure_names[i] = C.name

		// Get the cure name from the cures
		cure_text = jointext(cure_names, " & ")


	return

// Randomly generate a symptom, has a chance to lose or gain a symptom.
/datum/disease/advance/proc/Evolve(min_level, max_level)
	var/s = safepick(GenerateSymptoms(min_level, max_level, 1))
	if(s)
		AddSymptom(s)
		Refresh(1)
	return

// Randomly remove a symptom.
/datum/disease/advance/proc/Devolve()
	if(symptoms.len > 1)
		var/s = safepick(symptoms)
		if(s)
			RemoveSymptom(s)
			Refresh(1)
	return

// Name the disease.
/datum/disease/advance/proc/AssignName(name = "Unknown")
	src.name = name
	return

// Return a unique ID of the disease.
/datum/disease/advance/GetDiseaseID()
	if(!id)
		var/list/L = list()
		for(var/datum/symptom/S in symptoms)
			L += S.id
		L = sortList(L) // Sort the list so it doesn't matter which order the symptoms are in.
		var/result = jointext(L, ":")
		id = result
	return id


// Add a symptom, if it is over the limit (with a small chance to be able to go over)
// we take a random symptom away and add the new one.
/datum/disease/advance/proc/AddSymptom(datum/symptom/S)

	if(HasSymptom(S))
		return

	if(symptoms.len < (VIRUS_SYMPTOM_LIMIT - 1) + rand(-1, 1))
		symptoms += S
	else
		RemoveSymptom(pick(symptoms))
		symptoms += S
	return

// Simply removes the symptom.
/datum/disease/advance/proc/RemoveSymptom(datum/symptom/S)
	symptoms -= S
	return

/*

	Static Procs

*/

// Mix a list of advance diseases and return the mixed result.
/proc/Advance_Mix(list/D_list)

//	to_chat(world, "Mixing!!!!")

	var/list/diseases = list()

	for(var/datum/disease/advance/A in D_list)
		diseases += A.Copy()

	if(!diseases.len)
		return null
	if(diseases.len <= 1)
		return pick(diseases) // Just return the only entry.

	var/i = 0
	// Mix our diseases until we are left with only one result.
	while(i < 20 && diseases.len > 1)

		i++

		var/datum/disease/advance/D1 = pick(diseases)
		diseases -= D1

		var/datum/disease/advance/D2 = pick(diseases)
		D2.Mix(D1)

	// Should be only 1 entry left, but if not let's only return a single entry
	// to_chat(world, "END MIXING!!!!!")
	var/datum/disease/advance/to_return = pick(diseases)
	to_return.Refresh(1)
	return to_return

/proc/SetViruses(datum/reagent/R, list/data)
	if(data)
		var/list/preserve = list()
		if(istype(data) && data["viruses"])
			for(var/datum/disease/A in data["viruses"])
				preserve += A.Copy()
			R.data = data.Copy()
		if(preserve.len)
			R.data["viruses"] = preserve

/proc/AdminCreateVirus(client/user)

	if(!user)
		return

	var/i = VIRUS_SYMPTOM_LIMIT

	var/datum/disease/advance/D = new(0, null)
	D.symptoms = list()

	var/list/symptoms = list()
	symptoms += "Done"
	symptoms += GLOB.list_symptoms.Copy()
	do
		if(user)
			var/symptom = input(user, "Choose a symptom to add ([i] remaining)", "Choose a Symptom") in symptoms
			if(isnull(symptom))
				return
			else if(istext(symptom))
				i = 0
			else if(ispath(symptom))
				var/datum/symptom/S = new symptom
				if(!D.HasSymptom(S))
					D.symptoms += S
					i -= 1
	while(i > 0)

	if(D.symptoms.len > 0)

		var/new_name = stripped_input(user, "Name your new disease.", "New Name")
		if(!new_name)
			return
		D.AssignName(new_name)
		D.Refresh()

		for(var/datum/disease/advance/AD in GLOB.active_diseases)
			AD.Refresh()

		for(var/thing in shuffle(GLOB.human_list))
			var/mob/living/carbon/human/H = thing
			if(H.stat == DEAD || !is_station_level(H.z))
				continue
			if(!H.HasDisease(D))
				H.ForceContractDisease(D)
				break

		var/list/name_symptoms = list()
		for(var/datum/symptom/S in D.symptoms)
			name_symptoms += S.name
		message_admins("[key_name_admin(user)] has triggered a custom virus outbreak of [D.name]! It has these symptoms: [english_list(name_symptoms)]")



/datum/disease/advance/proc/totalStageSpeed()
	var/total_stage_speed = 0
	for(var/i in symptoms)
		var/datum/symptom/S = i
		total_stage_speed += S.stage_speed
	return total_stage_speed

/datum/disease/advance/proc/totalStealth()
	var/total_stealth = 0
	for(var/i in symptoms)
		var/datum/symptom/S = i
		total_stealth += S.stealth
	return total_stealth

/datum/disease/advance/proc/totalResistance()
	var/total_resistance = 0
	for(var/i in symptoms)
		var/datum/symptom/S = i
		total_resistance += S.resistance
	return total_resistance

/datum/disease/advance/proc/totalTransmittable()
	var/total_transmittable = 0
	for(var/i in symptoms)
		var/datum/symptom/S = i
		total_transmittable += S.transmittable
	return total_transmittable
