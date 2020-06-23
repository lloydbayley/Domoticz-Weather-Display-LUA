--
-- LUA Script to read from Weather Display XML file.
--

commandArray = {}

function XML_Capture(cmd,flatten)
   local f = assert(io.popen(cmd, 'r'))
   local s = assert(f:read('*a'))
   f:close()
   if flatten  then
      s = string.gsub(s, '^%s+', '')
      s = string.gsub(s, '%s+$', '')
      s = string.gsub(s, '[\n\r]+', ' ')
   end
   return s
end

-- Set debug to true to print to log file.
debug = false

-- Define the idx of your virtual sensors - i.e. what you have called your sensors and their IDX numbers
OUTDOOR_TEMP = 140
OFFICE_TEMP = 142
OUTDOOR_HUMIDITY = 143
INDOOR_HUMIDITY = 187
RAIN_TODAY = 146
WIND = 238

-- Define your device IP-address or URL (where the xml file lives)
Device_IP = "www.yourwebsite.com/weather"

if debug == true then
        print("Reading values from: 'http://"..Device_IP.."/wdfulldata.xml'")
end

-- Read the XML data from the device

XML_string=XML_Capture("curl -s 'http://"..Device_IP.."/wdfulldata.xml'",1)

valid = string.find(XML_string, "<WXDATA>")    -- check we are looking in the right place

    if debug == true then
        print(XML_string)
    end
   
    if valid == nil then
        print ("Bad XML status read - info NOT updated")
    else
 
-- Find in the XML_string the info-fields based on their labels

      outdoor_temp_reading = string.match(XML_string, "<temp>(.-)</temp>")
      outdoor_humidity_reading = string.match(XML_string, "<hum>(.-)</hum>")
      office_indoor_temp_reading = string.match(XML_string, "<indoortemp>(.-)</indoortemp>")
      office_indoor_hum_reading = string.match(XML_string, "<indoorhum>(.-)</indoorhum>")
      rainfall = string.match(XML_string, "<todayraininmm>(.-)</todayraininmm>")
      rain_rate = string.match(XML_string, "<rainrate>(.-)</rainrate>")
      wind_direction_degrees = string.match(XML_string, "<dirdeg>(.-)</dirdeg>")
      wind_direction_label = string.match(XML_string, "<dirlabel>(.-)</dirlabel>")
      wind_speed = string.match(XML_string, "<avgspd>(.-)</avgspd>")
      wind_gust = string.match(XML_string, "<gstspd>(.-)</gstspd>")
      wind_chill = string.match(XML_string, "<windch>(.-)</windch>")
     

-- Conversions/Static values

      -- Convert Wind values from km/h to m/s
      wind_speed = wind_speed * 10 * 0.278
      wind_gust = wind_gust * 10 * 0.278

      -- Convert rain rate to mm / 100
      rain_rate = rain_rate * 100

if debug == true then

      print('WindSpeed m/s: '.. wind_speed)
      print('WindGust m/s: ' .. wind_gust)

      print('Rainfall: ' .. rainfall)
      print('Rain Rate: ' .. rain_rate)

end

 
 -- Humidity Conditions (Work In Progress)
     
      sHumFeelsLike = "3"
      iHumFeelslike = "1"
      
      -- 0 is Normal, 1 = Comfortable, 2 = Dry, 3 = Wet
   
   
-- Temps   (Reference for future upgrades)
      
-- [1,5]=Very Cold
-- [5,18]=Cold
-- [18,21]=Cool
-- [21,27]=Comfortable
-- [27,32]=Caution: fatigue is possible with prolonged exposure and activity. Continuing activity could result in heat cramps.
-- [32,41]=Extreme caution: heat cramps and heat exhaustion are possible. Continuing activity could result in heat stroke
-- [41,54]=Danger: heat cramps and heat exhaustion are likely; heat stroke is probable with continued activity.
-- [54,100]=Extreme danger: heat stroke is imminent.
      


-- Upload to Domoticz
     
        commandArray[1] = {['UpdateDevice'] = OUTDOOR_TEMP..'|0|'..tostring(outdoor_temp_reading)}
        commandArray[2] = {['UpdateDevice'] = OFFICE_TEMP..'|0|'..tostring(office_indoor_temp_reading)}
        commandArray[3] = {['UpdateDevice'] = OUTDOOR_HUMIDITY .. '|' .. tostring(outdoor_humidity_reading) .. '|' .. tostring(sHumFeelsLike)}
        commandArray[4] = {['UpdateDevice'] = RAIN_TODAY .. '|0|' .. tostring(rain_rate) .. ';' .. tostring(rainfall)}
        commandArray[5] = {['UpdateDevice'] = INDOOR_HUMIDITY..'|'.. tostring(office_indoor_hum_reading) .. '|' .. tostring(iHumFeelsLike)}
        commandArray[6] = {['UpdateDevice'] = WIND..'|0|'.. tostring(wind_direction_degrees)..';'..tostring(wind_direction_label)..';'..tostring(wind_speed)..';'..tostring(wind_gust)..';'..tostring(outdoor_temp_reading)..';'..tostring(wind_chill)}     
        commandArray[7] = {['Variable:DailyRain'] = rainfall}

 

    end
 
return commandArray
