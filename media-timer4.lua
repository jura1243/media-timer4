obs = obslua

currentUsedMediaSourceName = ""
manualSelectedMediaSourceName = ""
textSourceName = ""

last_text = ""

-- jura
mypr = false

-- converted
-- patched log
-- added summ time

function timer_callback()
    mediaSource = obs.obs_get_source_by_name(currentUsedMediaSourceName)
    if mediaSource == nil then
        obs.obs_source_release(mediaSource)
        return
    end

    local time = obs.obs_source_media_get_time(mediaSource)
    local duration = obs.obs_source_media_get_duration(mediaSource)
    obs.obs_source_release(mediaSource)

    local timeLeft = duration - time;

    local seconds = string.sub('0'..(math.floor(timeLeft / 1000) % 60), -2)
    local minutes = string.sub('0'..math.floor(timeLeft / 1000 / 60) % 60, -2)
    local hours = math.floor(timeLeft / 1000 / 60 / 60)
    local text = '-'..hours..':'..minutes..':'..seconds

-- jura
if mypr == true then
    local myduration =math.floor(duration / 1000 / 60 / 60)..':'..string.sub('0'..math.floor(duration / 1000 / 60) % 60, -2)..':'..string.sub('0'..(math.floor(duration / 1000) % 60), -2)
    text = '-'..hours..':'..minutes..':'..seconds..'/'..myduration
end

    if(text == last_text) then
        return
    end

    local source = obs.obs_get_source_by_name(textSourceName)
    if source ~= nil then
        local settings = obs.obs_data_create()
        obs.obs_data_set_string(settings, "text", text)
        obs.obs_source_update(source, settings)
        obs.obs_data_release(settings)
        obs.obs_source_release(source)
    end

    last_text = text
end

function media_started(param, data)
    obs.timer_add(timer_callback, 1000)
end

function media_ended(param, data)
    obs.timer_remove(timer_callback)
end

function source_activated(cd)
    local source = obs.calldata_source(cd, "source")
    
    --If manual mode is active, we only activate te source if it is the selected source
    if(isManualModeActive() and obs.obs_source_get_name(source) ~= manualSelectedMediaSourceName) then
        return
    end

	select_source(source)
end

function source_deactivated(cd)
    local source = obs.calldata_source(cd, "source")
    deselect_source(source)
end

function select_source(source)
    if(source == nil) then
        return
    end

    local sourceId = obs.obs_source_get_id(source)
    if(sourceId == 'ffmpeg_source' or sourceId == 'vlc_source') then
        local sh = obs.obs_source_get_signal_handler(source)

        currentUsedMediaSourceName = obs.obs_source_get_name(source)
        obs.signal_handler_connect(sh, "media_started", media_started)
        obs.signal_handler_connect(sh, "media_stopped", media_ended)

        if(obs.obs_source_media_get_state(source) == 1) then
            obs.timer_add(timer_callback, 1000)
        end
    end
end

function deselect_source(source)
    if(source == nil) then
        return
    end

    local sourceId = obs.obs_source_get_id(source)
    local sourceName = obs.obs_source_get_name(source)

    if(sourceId == 'ffmpeg_source' or sourceId == 'vlc_source') then
        local sh = obs.obs_source_get_signal_handler(source)
        obs.signal_handler_disconnect(sh, "media_started", media_started)
        obs.signal_handler_disconnect(sh, "media_stopped", media_ended)

        if(currentUsedMediaSourceName == sourceName) then
            obs.timer_remove(timer_callback)
            currentUsedMediaSourceName = ""
        end
    end
end

function isManualModeActive()
    
    return manualSelectedMediaSourceName ~= "" and manualSelectedMediaSourceName ~= "---AUTO---"
end

function refresh()
    
    if(currentUsedMediaSourceName ~= "") then
        local source = obs.obs_get_source_by_name(currentUsedMediaSourceName)
        deselect_source(source)
        obs.obs_source_release(source)
    end

    if(isManualModeActive()) then
        local source = obs.obs_get_source_by_name(manualSelectedMediaSourceName)
        select_source(source)
        obs.obs_source_release(source)
        return
    end

    local sources = obs.obs_enum_sources()
	if sources ~= nil then
		for _, source in ipairs(sources) do
			source_id = obs.obs_source_get_unversioned_id(source)
            if source_id == 'ffmpeg_source' or source_id == 'vlc_source' then
                if(obs.obs_source_active(source)) then
                    select_source(source, true)
                end
			end
		end
	end
	obs.source_list_release(sources)
end

----------------------------------------------------------------------------------------------

function script_load(settings)
--    log(300, 'started')
    obs.script_log(obs.LOG_INFO, "started")


    local sh = obs.obs_get_signal_handler()
	obs.signal_handler_connect(sh, "source_activate", source_activated)
    obs.signal_handler_connect(sh, "source_deactivate", source_deactivated)

    refresh()
end

function script_unload()
--    log(300, 'ended')
    obs.script_log(obs.LOG_INFO, "ended")
end

function script_description()
	return "Sets a text source to act as a media countdown timer when a media source is active.\n\nMade by Luuk Verhagen, patched by jura12"
end

function script_properties()
	local props = obs.obs_properties_create()

	local p = obs.obs_properties_add_list(props, "source", "Text Source", obs.OBS_COMBO_TYPE_EDITABLE, obs.OBS_COMBO_FORMAT_STRING)
    local mediaSourceList = obs.obs_properties_add_list(props, "mediaSource", "Selected media source", obs.OBS_COMBO_TYPE_EDITABLE, obs.OBS_COMBO_FORMAT_STRING)

--jura
-- obs_properties_add_bool(obs_properties_t *props, const char *name, const char *description);
    local myprintsumm=obs.obs_properties_add_bool(props, "duration", "Show all time.")

    obs.obs_property_list_add_string(mediaSourceList, "---AUTO---", "auto")

	local sources = obs.obs_enum_sources()
	if sources ~= nil then
		for _, source in ipairs(sources) do
			source_id = obs.obs_source_get_unversioned_id(source)
            if source_id == "text_gdiplus" or source_id == "text_ft2_source" then
                local name = obs.obs_source_get_name(source)
                obs.obs_property_list_add_string(p, name, name)
			end
            if source_id == 'ffmpeg_source' or source_id == 'vlc_source' then
                local name = obs.obs_source_get_name(source)
                obs.obs_property_list_add_string(mediaSourceList, name, name)
            end
		end
	end
	obs.source_list_release(sources)

	return props
end

function script_update(settings)
	textSourceName = obs.obs_data_get_string(settings, "source")
	manualSelectedMediaSourceName = obs.obs_data_get_string(settings, "mediaSource")
-- jura
	mypr = obs.obs_data_get_bool(settings, "duration")

    refresh()
end

function script_defaults(settings)
end