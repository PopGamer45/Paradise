/obj/machinery/computer/camera_advanced/hit_run_teleporter
	name = "hit and run teleporter console"
	desc = "A syndicate teleporter \"inspired\" by the abductor's teleportation technology."
	icon = 'icons/obj/abductor.dmi'
	icon_state = "camera_syndi"
	icon_screen = "camera_syndi_screen"
	networks = list("SS13")
	circuit = /obj/item/circuitboard/syndi_teleporter
	power_state = NO_POWER_USE
	interact_offline = TRUE
	var/datum/action/innate/teleport_in/syndi/tele_in_action = new
	var/obj/machinery/syndi_telepad/linked_pad

/obj/machinery/computer/camera_advanced/hit_run_teleporter/Initialize(mapload)
	. = ..()
	if(!isfloorturf(loc))
		anchored = FALSE
	try_link_pad()

/obj/machinery/computer/camera_advanced/hit_run_teleporter/Destroy()
	if(linked_pad)
		linked_pad.linked_console = null
	return ..()

/obj/machinery/computer/camera_advanced/hit_run_teleporter/CreateEye()
	..()
	eyeobj.visible_icon = TRUE
	eyeobj.icon = 'icons/obj/abductor.dmi'
	eyeobj.icon_state = "camera_target"

/obj/machinery/computer/camera_advanced/hit_run_teleporter/GrantActions(mob/living/carbon/user)
	..()

	if(tele_in_action)
		tele_in_action.target = linked_pad
		tele_in_action.Grant(user)
		actions += tele_in_action

/obj/machinery/computer/camera_advanced/hit_run_teleporter/proc/try_link_pad()
	if(linked_pad)
		return
	for(var/obj/machinery/syndi_telepad/T in range(1, src))
		if(T.linked_console || !T.anchored)
			continue
		linked_pad = T
		T.linked_console = src
		tele_in_action.target = T
		return

/obj/item/gps/internal/hit_run_teleporter
	icon_state = null
	gpstag = "Suspicious Bluespace Signal"
	desc = "This signal is snooping in the station's camera network, hide your passwords!"

/datum/action/innate/teleport_in/syndi
	name = "Send To"
	button_icon_state = "beam_down"

/datum/action/innate/teleport_in/syndi/Activate()
	if(!target || !iscarbon(owner))
		return
	var/mob/living/carbon/human/C = owner
	var/mob/camera/aiEye/remote/remote_eye = C.remote_control
	var/obj/machinery/syndi_telepad/P = target

	if(GLOB.cameranet.checkTurfVis(remote_eye.loc))
		P.Teleport_In(get_turf(remote_eye), owner)

/obj/machinery/syndi_telepad
	name = "hit and run telepad"
	desc = "Used to teleport in and then quickly back out"
	icon = 'icons/obj/abductor.dmi'
	icon_state = "syndi-pad-idle"
	anchored = TRUE
	power_state = NO_POWER_USE
	interact_offline = TRUE
	var/cooldown = 0
	var/cooldown_time = 3 MINUTES
	var/retrieve_timer = 45 SECONDS
	var/about_to_retrieve = FALSE
	var/obj/item/gps/internal/gps_signal = /obj/item/gps/internal/hit_run_teleporter
	var/obj/machinery/computer/camera_advanced/hit_run_teleporter/linked_console

/obj/machinery/syndi_telepad/Initialize(mapload)
	. = ..()
	try_link_console()
	gps_signal = new gps_signal(src)
	if(!isfloorturf(loc))
		anchored = FALSE
	component_parts = list()
	component_parts += new /obj/item/circuitboard/syndi_telepad(null)
	component_parts += new /obj/item/stack/ore/bluespace_crystal/artificial(null, 2)
	component_parts += new /obj/item/stock_parts/matter_bin(null)
	component_parts += new /obj/item/stock_parts/manipulator(null)
	RefreshParts()

/obj/machinery/syndi_telepad/Destroy()
	if(linked_console)
		linked_console.linked_pad = null
	QDEL_NULL(gps_signal)
	return ..()

/obj/machinery/syndi_telepad/update_icon_state()
	if(panel_open)
		icon_state = "syndi-pad-o"
	else
		icon_state = "syndi-pad-idle"

/obj/machinery/syndi_telepad/screwdriver_act(mob/user, obj/item/I)
	if(default_deconstruction_screwdriver(user, "[initial(icon_state)]-o", initial(icon_state), I))
		update_icon(UPDATE_ICON_STATE)
		return TRUE

/obj/machinery/syndi_telepad/crowbar_act(mob/living/user, obj/item/I)
	. = TRUE
	if(cooldown > world.time)
		to_chat(user, "<span class='notice'>The maintenance panel is locked.</span>")
		return
	if(default_deconstruction_crowbar(user, I))
		return

/obj/machinery/syndi_telepad/wrench_act(mob/user, obj/item/I)
	. = TRUE
	if(about_to_retrieve)
		to_chat(user, "<span class='warning'>The bolts are locked down!</span>")
		return
	if(default_unfasten_wrench(user, I))
		try_link_console(TRUE)
		return

/obj/machinery/syndi_telepad/proc/try_link_console(relink)
	if(relink && linked_console)
		linked_console.linked_pad = null
		linked_console = null
	if(linked_console || !anchored)
		return
	for(var/obj/machinery/computer/camera_advanced/hit_run_teleporter/T in range(1, src))
		if(T.linked_pad)
			continue
		linked_console = T
		T.linked_pad = src
		T.tele_in_action.target = src
		return

/obj/machinery/syndi_telepad/proc/Teleport_Out(mob/living/carbon/target)
	if(stat & (BROKEN))
		return
	if(target.handcuffed && (target.buckled || target.pulledby))
		return
	flick("syndi-pad", src)
	new /obj/effect/temp_visual/dir_setting/ninja/cloak(get_turf(target), target.dir)
	do_sparks(10, 0, target.loc)
	target.forceMove(get_turf(src))
	do_sparks(10, 0, target.loc)
	about_to_retrieve = FALSE

/obj/machinery/syndi_telepad/proc/Teleport_In(turf/T, mob/living/carbon/user)
	if((stat & (BROKEN)))
		return
	if(cooldown > world.time)
		var/timeleft = cooldown - world.time
		to_chat(user, "<span class='notice'>[src] is still charging, wait [round(timeleft/10)] seconds.</span>")
		return
	if(!locate(/mob/living) in src.loc)
		return
	cooldown = world.time + cooldown_time
	new/obj/effect/temp_visual/teleport_abductor/syndi(T)
	sleep(25)
	flick("syndy-pad", src)
	for(var/mob/living/target in src.loc)
		target.forceMove(T)
		new /obj/effect/temp_visual/dir_setting/ninja(get_turf(target), target.dir)
		addtimer(CALLBACK(src, PROC_REF(Teleport_Out), target), retrieve_timer)
		about_to_retrieve = TRUE

/obj/effect/temp_visual/teleport_abductor/syndi
	duration = 25

/obj/item/storage/box/syndie_kit/hit_run_teleporter
	name = "hit and run teleporter kit"

/obj/item/storage/box/syndie_kit/hit_run_teleporter/populate_contents()
	new /obj/item/beacon/syndicate/bomb/syndi_teleporter(src)
	new /obj/item/beacon/syndicate/bomb/syndi_telepad(src)
