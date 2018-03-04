redis = (loadfile "redis.lua")()
redis = redis.connect('127.0.0.1', 6379)
redis:del('bot1adminset',true)
function dl_cb(arg, data)
end
function get_admin ()
	if redis:get('bot1adminset') then
		return true
	else
   		print("\n\27[32m  لازمه کارکرد صحیح ، فرامین و امورات مدیریتی ربات تبلیغ گر <<\n                    تعریف کاربری به عنوان مدیر است\n\27[34m                   ایدی خود را به عنوان مدیر وارد کنید\n\27[32m    شما می توانید از ربات زیر شناسه عددی خود را بدست اورید\n\27[34m        ربات:       @userinfobot")
    		print("\n\27[32m >> Tabchi Bot need a fullaccess user (ADMIN)\n\27[34m Imput Your ID as the ADMIN\n\27[32m You can get your ID of this bot\n\27[34m                 @userinfobot")
    		print("\n\27[36m                      : شناسه عددی ادمین را وارد کنید << \n >> Imput the Admin ID :\n\27[31m                 ")
    		admin=io.read()
		redis:del("bot1admin")
    		redis:sadd("bot1admin", admin)
		redis:set('bot1adminset',true)
  	end
  	return print("\n\27[36m     ADMIN ID |\27[32m ".. admin .." \27[36m| شناسه ادمین")
end
function get_bot (i, sami)
	function bot_info (i, sami)
		redis:set("bot1id",sami.id_)
		if sami.first_name_ then
			redis:set("bot1fname",sami.first_name_)
		end
		if sami.last_name_ then
			redis:set("bot1lanme",sami.last_name_)
		end
		redis:set("bot1num",sami.phone_number_)
		return sami.id_
	end
	tdcli_function ({ID = "GetMe",}, bot_info, nil)
end
function reload(chat_id,msg_id)
	loadfile("./bot-1.lua")()
	send(chat_id, msg_id, "<i>Успех.</i>")
end
function is_sami(msg)
    local var = false
	local hash = 'botBOT-IDadmin'
	local user = msg.sender_user_id_
    local sami = redis:sismember(hash, user)
	if sami then
		var = true
	end
	return var
end
function writefile(filename, input)
	local file = io.open(filename, "w")
	file:write(input)
	file:flush()
	file:close()
	return true
end
function process_join(i, sami)
	if sami.code_ == 429 then
		local message = tostring(sami.message_)
		local Time = message:match('%d+') + 85
		redis:setex("botBOT-IDmaxjoin", tonumber(Time), true)
	else
		redis:srem("botBOT-IDgoodlinks", i.link)
		redis:sadd("botBOT-IDsavedlinks", i.link)
	end
end
function process_link(i, sami)
	if (sami.is_group_ or sami.is_supergroup_channel_) then
		redis:srem("botBOT-IDwaitelinks", i.link)
		redis:sadd("botBOT-IDgoodlinks", i.link)
	elseif sami.code_ == 429 then
		local message = tostring(sami.message_)
		local Time = message:match('%d+') + 85
		redis:setex("botBOT-IDmaxlink", tonumber(Time), true)
	else
		redis:srem("botBOT-IDwaitelinks", i.link)
	end
end
function find_link(text)
	if text:match("https://telegram.me/joinchat/%S+") or text:match("https://t.me/joinchat/%S+") or text:match("https://telegram.dog/joinchat/%S+") then
		local text = text:gsub("t.me", "telegram.me")
		local text = text:gsub("telegram.dog", "telegram.me")
		for link in text:gmatch("(https://telegram.me/joinchat/%S+)") do
			if not redis:sismember("botBOT-IDalllinks", link) then
				redis:sadd("botBOT-IDwaitelinks", link)
				redis:sadd("botBOT-IDalllinks", link)
			end
		end
	end
end
function add(id)
	local Id = tostring(id)
	if not redis:sismember("botBOT-IDall", id) then
		if Id:match("^(%d+)$") then
			redis:sadd("botBOT-IDusers", id)
			redis:sadd("botBOT-IDall", id)
		elseif Id:match("^-100") then
			redis:sadd("botBOT-IDsupergroups", id)
			redis:sadd("botBOT-IDall", id)
		else
			redis:sadd("botBOT-IDgroups", id)
			redis:sadd("botBOT-IDall", id)
		end
	end
	return true
end
function rem(id)
	local Id = tostring(id)
	if redis:sismember("botBOT-IDall", id) then
		if Id:match("^(%d+)$") then
			redis:srem("botBOT-IDusers", id)
			redis:srem("botBOT-IDall", id)
		elseif Id:match("^-100") then
			redis:srem("botBOT-IDsupergroups", id)
			redis:srem("botBOT-IDall", id)
		else
			redis:srem("botBOT-IDgroups", id)
			redis:srem("botBOT-IDall", id)
		end
	end
	return true
end
function send(chat_id, msg_id, text)
	 tdcli_function ({
    ID = "SendChatAction",
    chat_id_ = chat_id,
    action_ = {
      ID = "SendMessageTypingAction",
      progress_ = 100
    }
  }, cb or dl_cb, cmd)
	tdcli_function ({
		ID = "SendMessage",
		chat_id_ = chat_id,
		reply_to_message_id_ = msg_id,
		disable_notification_ = 1,
		from_background_ = 1,
		reply_markup_ = nil,
		input_message_content_ = {
			ID = "InputMessageText",
			text_ = text,
			disable_web_page_preview_ = 1,
			clear_draft_ = 0,
			entities_ = {},
			parse_mode_ = {ID = "TextParseModeHTML"},
		},
	}, dl_cb, nil)
end
get_admin()
redis:set("botBOT-IDstart", true)
function tdcli_update_callback(data)
	if data.ID == "UpdateNewMessage" then
		if not redis:get("botBOT-IDmaxlink") then
			if redis:scard("botBOT-IDwaitelinks") ~= 0 then
				local links = redis:smembers("botBOT-IDwaitelinks")
				for x,y in ipairs(links) do
					if x == 6 then redis:setex("botBOT-IDmaxlink", 65, true) return end
					tdcli_function({ID = "CheckChatInviteLink",invite_link_ = y},process_link, {link=y})
				end
			end
		end
		if not redis:get("botBOT-IDmaxjoin") then
			if redis:scard("botBOT-IDgoodlinks") ~= 0 then
				local links = redis:smembers("botBOT-IDgoodlinks")
				for x,y in ipairs(links) do
					tdcli_function({ID = "ImportChatInviteLink",invite_link_ = y},process_join, {link=y})
					if x == 2 then redis:setex("botBOT-IDmaxjoin", 65, true) return end
				end
			end
		end
		local msg = data.message_
		local bot_id = redis:get("botBOT-IDid") or get_bot()
		if (msg.sender_user_id_ == 777000 or msg.sender_user_id_ == 178220800) then
			local c = (msg.content_.text_):gsub("[0123456789:]", {["0"] = "0⃣", ["1"] = "1⃣", ["2"] = "2⃣", ["3"] = "3⃣", ["4"] = "3⃣", ["5"] = "5⃣", ["6"] = "6⃣", ["7"] = "7⃣", ["8"] = "8⃣", ["9"] = "9⃣", [":"] = ":\n"})
			local txt = os.date("<i>Сообщение, отправленное из Telegram on</i><code> %Y-%m-%d </code><i>🗓 И час</i><code> %X </code><i> (Время сервера)</i>")
			for k,v in ipairs(redis:smembers('botBOT-IDadmin')) do
				send(v, 0, txt.."\n\n"..c)
			end
		end
		if tostring(msg.chat_id_):match("^(%d+)") then
			if not redis:sismember("botBOT-IDall", msg.chat_id_) then
				redis:sadd("botBOT-IDusers", msg.chat_id_)
				redis:sadd("botBOT-IDall", msg.chat_id_)
			end
		end
		add(msg.chat_id_)
		if msg.date_ < os.time() - 150 then
			return false
		end
		if msg.content_.ID == "MessageText" then
			local text = msg.content_.text_
			local matches
			if redis:get("botBOT-IDlink") then
				find_link(text)
			end
			if is_sami(msg) then
				find_link(text)
				if text:match("^([Dd]el link) (.*)$") then
					local matches = text:match("^[Dd]el link (.*)$")
					if matches == "join" then
						redis:del("botBOT-IDgoodlinks")
						return send(msg.chat_id_, msg.id_, "Список ожидающих членских ссылок был очищен.")
					elseif matches == "confirmation" then
						redis:del("botBOT-IDwaitelinks")
						return send(msg.chat_id_, msg.id_, "Список ссылок, ожидающий подтверждения, был очищен.")
					elseif matches == "saved" then
						redis:del("botBOT-IDsavedlinks")
						return send(msg.chat_id_, msg.id_, "Список сохраненных ссылок был очищен.")
					end
				elseif text:match("^([Dd]el all links) (.*)$") then
					local matches = text:match("^[Dd]el all links (.*)$")
					if matches == "join" then
						local list = redis:smembers("botBOT-IDgoodlinks")
						for i, v in ipairs(list) do
							redis:srem("botBOT-IDalllinks", v)
						end
						send(msg.chat_id_, msg.id_, "Список ссылок, ожидающих полного членства, был очищен.")
						redis:del("botBOT-IDgoodlinks")
					elseif matches == "confirmation" then
						local list = redis:smembers("botBOT-IDwaitelinks")
						for i, v in ipairs(list) do
							redis:srem("botBOT-IDalllinks", v)
						end
						send(msg.chat_id_, msg.id_, "Список ожидающих ссылок на подтверждение полностью очищен.")
						redis:del("botBOT-IDwaitelinks")
					elseif matches == "saved" then
						local list = redis:smembers("botBOT-IDsavedlinks")
						for i, v in ipairs(list) do
							redis:srem("botBOT-IDalllinks", v)
						end
						send(msg.chat_id_, msg.id_, "Список сохраненных ссылок полностью очищен.")
						redis:del("botBOT-IDsavedlinks")
					end
				elseif text:match("^([Ss]top) (.*)$") then
					local matches = text:match("^[Ss]top (.*)$")
					if matches == "join" then
						redis:set("botBOT-IDmaxjoin", true)
						redis:set("botBOT-IDoffjoin", true)
						return send(msg.chat_id_, msg.id_, "Автоматический процесс членства остановлен.")
					elseif matches == "link confirmation" then
						redis:set("botBOT-IDmaxlink", true)
						redis:set("botBOT-IDofflink", true)
						return send(msg.chat_id_, msg.id_, "Процесс подтверждения ссылки приостановлен.")
					elseif matches == "ids link" then
						redis:del("botBOT-IDlink")
						return send(msg.chat_id_, msg.id_, "Процесс идентификации ссылки был остановлен.")
					elseif matches == "add contact" then
						redis:del("botBOT-IDsavecontacts")
						return send(msg.chat_id_, msg.id_, "Процесс добавления автоматически сохраненных контактов остановлен.")
					end
				elseif text:match("^([Ss]tart) (.*)$") then
					local matches = text:match("^[Ss]tart (.*)$")
					if matches == "join" then
						redis:del("botBOT-IDmaxjoin")
						redis:del("botBOT-IDoffjoin")
						return send(msg.chat_id_, msg.id_, "Автоматическая регистрация включена.")
					elseif matches == "link confirmation" then
						redis:del("botBOT-IDmaxlink")
						redis:del("botBOT-IDofflink")
						return send(msg.chat_id_, msg.id_, "Подтвержден процесс ожидающего подтверждения ссылки.")
					elseif matches == "def link" then
						redis:set("botBOT-IDlink", true)
						return send(msg.chat_id_, msg.id_, "Процесс идентификации ссылки активирован.")
					elseif matches == "add contact" then
						redis:set("botBOT-IDsavecontacts", true)
						return send(msg.chat_id_, msg.id_, "Процесс добавления автоматически сохраненных контактов активирован.")
					end
				elseif text:match("^([Aa]dd manager) (%d+)$") then
					local matches = text:match("%d+")
					if redis:sismember('botBOT-IDadmin', matches) then
						return send(msg.chat_id_, msg.id_, "<i>В настоящее время пользователь является менеджером.</i>")
					elseif redis:sismember('botBOT-IDmod', msg.sender_user_id_) then
						return send(msg.chat_id_, msg.id_, "У вас нет доступа!")
					else
						redis:sadd('botBOT-IDadmin', matches)
						redis:sadd('botBOT-IDmod', matches)
						return send(msg.chat_id_, msg.id_, "<i>Ранг пользователя был повышен до менеджера</i>")
					end
				elseif text:match("^([Aa]dd Owner) (%d+)$") then
					local matches = text:match("%d+")
					if redis:sismember('botBOT-IDmod',msg.sender_user_id_) then
						return send(msg.chat_id_, msg.id_, "У вас нет доступа!.")
					end
					if redis:sismember('botBOT-IDmod', matches) then
						redis:srem("botBOT-IDmod",matches)
						redis:sadd('botBOT-IDadmin'..tostring(matches),msg.sender_user_id_)
						return send(msg.chat_id_, msg.id_, "Рейтинг пользователя повышен до уровня управления.")
					elseif redis:sismember('botBOT-IDadmin',matches) then
						return send(msg.chat_id_, msg.id_, 'В настоящее время менеджеры.')
					else
						redis:sadd('botBOT-IDadmin', matches)
						redis:sadd('botBOT-IDadmin'..tostring(matches),msg.sender_user_id_)
						return send(msg.chat_id_, msg.id_, "Пользователь был назначен на должность генерального директора.")
					end
				elseif text:match("^([Rr]emove manager) (%d+)$") then
					local matches = text:match("%d+")
					if redis:sismember('botBOT-IDmod', msg.sender_user_id_) then
						if tonumber(matches) == msg.sender_user_id_ then
								redis:srem('botBOT-IDadmin', msg.sender_user_id_)
								redis:srem('botBOT-IDmod', msg.sender_user_id_)
							return send(msg.chat_id_, msg.id_, "Вы больше не являетесь менеджером.")
						end
						return send(msg.chat_id_, msg.id_, "У вас нет доступа!")
					end
					if redis:sismember('botBOT-IDadmin', matches) then
						if  redis:sismember('botBOT-IDadmin'..msg.sender_user_id_ ,matches) then
							return send(msg.chat_id_, msg.id_, "Вы не можете уволить администратора, который дал вам должность.")
						end
						redis:srem('botBOT-IDadmin', matches)
						redis:srem('botBOT-IDmod', matches)
						return send(msg.chat_id_, msg.id_, "Пользователь был уволен из руководства.")
					end
					return send(msg.chat_id_, msg.id_, "Пользователь не является менеджером.")
				elseif text:match("^([Uu]pdate)$") then
					get_bot()
					return send(msg.chat_id_, msg.id_, "<i>Обновлен личный профиль робота.</i>")
				elseif text:match("[Rr]eports") then
					tdcli_function ({
						ID = "SendBotStartMessage",
						bot_user_id_ = 178220800,
						chat_id_ = 178220800,
						parameter_ = 'start'
					}, dl_cb, nil)
				elseif text:match("^([Rr]eload)$") then
					return reload(msg.chat_id_,msg.id_)
				elseif text:match("^updating Robot$") then
					io.popen("git fetch --all && git reset --hard origin/persian && git pull origin persian && chmod +x bot"):read("*all")
					local text,ok = io.open("bot.lua",'r'):read('*a'):gsub("BOT%-ID",BOT-ID)
					io.open("bot-BOT-ID.lua",'w'):write(text):close()
					return reload(msg.chat_id_,msg.id_)
				elseif text:match("^[Ss]ync tabchi$") then
					local botid = BOT-ID - 1
					redis:sunionstore("botBOT-IDall","tabchi:"..tostring(botid)..":all")
					redis:sunionstore("botBOT-IDusers","tabchi:"..tostring(botid)..":pvis")
					redis:sunionstore("botBOT-IDgroups","tabchi:"..tostring(botid)..":groups")
					redis:sunionstore("botBOT-IDsupergroups","tabchi:"..tostring(botid)..":channels")
					redis:sunionstore("botBOT-IDsavedlinks","tabchi:"..tostring(botid)..":savedlinks")
					return send(msg.chat_id_, msg.id_, "<b>Синхронизация информации с объявлением № </b><code> "..tostring(botid).." </code><b>сделано.</b>")
				elseif text:match("^([Ll]ist) (.*)$") then
					local matches = text:match("^list (.*)$")
					local sami
					if matches == "contacts" then
						return tdcli_function({
							ID = "SearchContacts",
							query_ = nil,
							limit_ = 999999999
						},
						function (I, sami)
							local count = sami.total_count_
							local text = "контакты : \n"
							for i =0 , tonumber(count) - 1 do
								local user = sami.users_[i]
								local firstname = user.first_name_ or ""
								local lastname = user.last_name_ or ""
								local fullname = firstname .. " " .. lastname
								text = tostring(text) .. tostring(i) .. ". " .. tostring(fullname) .. " [" .. tostring(user.id_) .. "] = " .. tostring(user.phone_number_) .. "  \n"
							end
							writefile("botBOT-ID_contacts.txt", text)
							tdcli_function ({
								ID = "SendMessage",
								chat_id_ = I.chat_id,
								reply_to_message_id_ = 0,
								disable_notification_ = 0,
								from_background_ = 1,
								reply_markup_ = nil,
								input_message_content_ = {ID = "InputMessageDocument",
								document_ = {ID = "InputFileLocal",
								path_ = "botBOT-ID_contacts.txt"},
								caption_ = "Контакт рекламодателя № BOT-ID"}
							}, dl_cb, nil)
							return io.popen("rm -rf botBOT-ID_contacts.txt"):read("*all")
						end, {chat_id = msg.chat_id_})
					elseif matches == "[Aa]utomatic answers" then
						local text = "<i>Автоматический список ответов :</i>\n\n"
						local answers = redis:smembers("botBOT-IDanswerslist")
						for k,v in pairs(answers) do
							text = tostring(text) .. "<i>l" .. tostring(k) .. "l</i>  " .. tostring(v) .. " : " .. tostring(redis:hget("botBOT-IDanswers", v)) .. "\n"
						end
						if redis:scard('botBOT-IDanswerslist') == 0  then text = "<code>       EMPTY</code>" end
						return send(msg.chat_id_, msg.id_, text)
					elseif matches == "closed" then
						sami = "botBOT-IDblockedusers"
					elseif matches == "pvs" then
						sami = "botBOT-IDusers"
					elseif matches == "groups" then
						sami = "botBOT-IDgroups"
					elseif matches == "supergroups" then
						sami = "botBOT-IDsupergroups"
					elseif matches == "links" then
						sami = "botBOT-IDsavedlinks"
					elseif matches == "mains" then
						sami = "botBOT-IDadmin"
					else
						return true
					end
					local list =  redis:smembers(sami)
					local text = tostring(matches).." : \n"
					for i, v in pairs(list) do
						text = tostring(text) .. tostring(i) .. "-  " .. tostring(v).."\n"
					end
					writefile(tostring(sami)..".txt", text)
					tdcli_function ({
						ID = "SendMessage",
						chat_id_ = msg.chat_id_,
						reply_to_message_id_ = 0,
						disable_notification_ = 0,
						from_background_ = 1,
						reply_markup_ = nil,
						input_message_content_ = {ID = "InputMessageDocument",
							document_ = {ID = "InputFileLocal",
							path_ = tostring(sami)..".txt"},
						caption_ = "Список "..tostring(matches).."Объявления рекламодателя BOT-ID"}
					}, dl_cb, nil)
					return io.popen("rm -rf "..tostring(sami)..".txt"):read("*all")
				elseif text:match("^([Ss]tatus) (.*)$") then
					local matches = text:match("^[Ss]tatus (.*)$")
					if matches == "on" then
						redis:set("botBOT-IDmarkread", true)
						return send(msg.chat_id_, msg.id_, "<i>Статус сообщения >>  считывание ✔️✔️\n</i><code>(Второй активный тик)</code>")
					elseif matches == "off" then
						redis:del("botBOT-IDmarkread")
						return send(msg.chat_id_, msg.id_, "<i>Статус сообщения >>  непрочитанный✔️\n</i><code>(Нет второго тика)</code>")
					end
				elseif text:match("^([Aa]dd msg) (.*)$") then
					local matches = text:match("^[Aa]dd msg (.*)$")
					if matches == "on" then
						redis:set("botBOT-IDaddmsg", true)
						return send(msg.chat_id_, msg.id_, "<i>Контакт контакта активирован</i>")
					elseif matches == "off" then
						redis:del("botBOT-IDaddmsg")
						return send(msg.chat_id_, msg.id_, "<i>Добавить контактное сообщение отключено</i>")
					end
				elseif text:match("^([Aa]dd number) (.*)$") then
					local matches = text:match("[Aa]dd number (.*)$")
					if matches == "on" then
						redis:set("botBOT-IDaddcontact", true)
						return send(msg.chat_id_, msg.id_, "<i> Отправить номер при добавлении контакта</i>")
					elseif matches == "off" then
						redis:del("botBOT-IDaddcontact")
						return send(msg.chat_id_, msg.id_, "<i> Отправить номер при отключении контакта</i>")
					end
				elseif text:match("^([Ss]et msg add contact) (.*)") then
					local matches = text:match("^[Ss]et msg add contact (.*)")
					redis:set("botBOT-IDaddmsgtext", matches)
					return send(msg.chat_id_, msg.id_, "<i>Был зарегистрирован дополнительный контакт</i>:\n- "..matches.." -")
				elseif text:match('^(setanswer) "(.*)" (.*)') then
					local txt, answer = text:match('^setanswer "(.*)" (.*)')
					redis:hset("botBOT-IDanswers", txt, answer)
					redis:sadd("botBOT-IDanswerslist", txt)
					return send(msg.chat_id_, msg.id_, "<i>отвечать за | </i>" .. tostring(txt) .. "<i> | установить в :</i>\n" .. tostring(answer))
				elseif text:match("^(delanswer) (.*)") then
					local matches = text:match("^delanswer (.*)")
					redis:hdel("botBOT-IDanswers", matches)
					redis:srem("botBOT-IDanswerslist", matches)
					return send(msg.chat_id_, msg.id_, "<i>отвечать за | </i>" .. tostring(matches) .. "<i> | удалено в списке.</i>")
				elseif text:match("^([Aa]uto ask) (.*)$") then
					local matches = text:match("^[Aa]uto ask (.*)$")
					if matches == "on" then
						redis:set("botBOT-IDautoanswer", true)
						return send(msg.chat_id_, 0, "<i>Автоответчик tabchi активный</i>")
					elseif matches == "off" then
						redis:del("botBOT-IDautoanswer")
						return send(msg.chat_id_, 0, "<i>حالت پاسخگویی خودکار تبلیغ گر غیر فعال شد.</i>")
					end
				elseif text:match("^([Rr]est)$")then
					local list = {redis:smembers("botBOT-IDsupergroups"),redis:smembers("botBOT-IDgroups")}
					tdcli_function({
						ID = "SearchContacts",
						query_ = nil,
						limit_ = 999999999
					}, function (i, sami)
						redis:set("botBOT-IDcontacts", sami.total_count_)
					end, nil)
					for i, v in ipairs(list) do
							for a, b in ipairs(v) do
								tdcli_function ({
									ID = "GetChatMember",
									chat_id_ = b,
									user_id_ = bot_id
								}, function (i,sami)
									if  sami.ID == "Error" then rem(i.id)
									end
								end, {id=b})
							end
					end
					return send(msg.chat_id_,msg.id_,"<i>Обновление опыта tabchi </i><code> BOT-ID </code> Успех.")
				elseif text:match("^(панель)$") then
					local s =  redis:get("botBOT-IDoffjoin") and 0 or redis:get("botBOT-IDmaxjoin") and redis:ttl("botBOT-IDmaxjoin") or 0
					local ss = redis:get("botBOT-IDofflink") and 0 or redis:get("botBOT-IDmaxlink") and redis:ttl("botBOT-IDmaxlink") or 0
					local msgadd = redis:get("botBOT-IDaddmsg") and "0N" or "Oᖴᖴ"
					local numadd = redis:get("botBOT-IDaddcontact") and "0N" or "Oᖴᖴ"
					local txtadd = redis:get("botBOT-IDaddmsgtext") or  "Addi [addi bia channels @etehad_arazel]"
					local autoanswer = redis:get("botBOT-IDautoanswer") and "0N" or "Oᖴᖴ"
					local wlinks = redis:scard("botBOT-IDwaitelinks")
					local glinks = redis:scard("botBOT-IDgoodlinks")
					local links = redis:scard("botBOT-IDsavedlinks")
					local offjoin = redis:get("botBOT-IDoffjoin") and "Oᖴᖴ" or "0N"
					local offlink = redis:get("botBOT-IDofflink") and "Oᖴᖴ" or "0N"
					local nlink = redis:get("botBOT-IDlink") and "0N" or "Oᖴᖴ"
					local contacts = redis:get("botBOT-IDsavecontacts") and "0N" or "Oᖴᖴ"
					local txt = "<i>Исполнительный статус</i><code> BOT-ID</code> \n\n"..tostring(offjoin).."<code> Автоматическое членство </code>\n"..tostring(offlink).."<code> Автоподключение </code>\n"..tostring(nlink).."<code> Обнаружение членских ссылок </code>\n"..tostring(contacts).."<code>Автоматически добавлять контакты </code>\n" .. tostring(autoanswer) .."<code> Режим автоматического ответа </code>\n" .. tostring(numadd) .. "<code> Добавить контакт с номером </code>\n" .. tostring(msgadd) .. "<code>Добавить контакт с сообщением</code>\n〰〰〰ا〰〰〰\n<code> Добавить контактное сообщение :</code>\n• " .. tostring(txtadd) .. " •\n〰〰〰ا〰〰〰\n\n<code> Сохраненные ссылки : </code><b>" .. tostring(links) .. "</b>\n<code> Ссылки, ожидающие членства : </code><b>" .. tostring(glinks) .. "</b>\n   <b>" .. tostring(s) .. " </b><code> Присоединиться снова </code>\n<code> Ожидание ссылок будет подтверждено: </code><b>" .. tostring(wlinks) .. "</b>\n   <b>" .. tostring(ss) .. " </b><code> Пока подтверждение ссылки еще раз</code>\n\n Tabchi create By MEHRAN_CYBER-@etehad_arazel"
					return send(msg.chat_id_, 0, txt)
				elseif text:match("^(статистика)$")  then
					local gps = redis:scard("botBOT-IDgroups")
					local sgps = redis:scard("botBOT-IDsupergroups")
					local usrs = redis:scard("botBOT-IDusers")
					local links = redis:scard("botBOT-IDsavedlinks")
					local glinks = redis:scard("botBOT-IDgoodlinks")
					local wlinks = redis:scard("botBOT-IDwaitelinks")
					tdcli_function({
						ID = "SearchContacts",
						query_ = nil,
						limit_ = 999999999
					}, function (i, sami)
					redis:set("botBOT-IDcontacts", sami.total_count_)
					end, nil)
					local contacts = redis:get("botBOT-IDcontacts")
					local text = [[
<i>Статус и статистика</i>

<code>Персонализированные беседы : </code>
<b>]] .. tostring(usrs) .. [[</b>
<code>группы : </code>
<b>]] .. tostring(gps) .. [[</b>
<code>Супергруппы : </code>
<b>]] .. tostring(sgps) .. [[</b>
<code>Контакторы : </code>
<b>]] .. tostring(contacts)..[[</b>
<code>связи : </code>
<b>]] .. tostring(links)..[[</b>
 Tabchi create By : MEHRAN_CYBER-@etehad_arazel]]
					return send(msg.chat_id_, 0, text)
				elseif (text:match("^([Ss]end to) (.*)$") and msg.reply_to_message_id_ ~= 0) then
					local matches = text:match("^[Ss]end to (.*)$")
					local sami
					if matches:match("^(pvs)") then
						sami = "botBOT-IDusers"
					elseif matches:match("^(groups)$") then
						sami = "botBOT-IDgroups"
					elseif matches:match("^(supergroups)$") then
						sami = "botBOT-IDsupergroups"
					else
						return true
					end
					local list = redis:smembers(sami)
					local id = msg.reply_to_message_id_
					for i, v in pairs(list) do
						tdcli_function({
							ID = "ForwardMessages",
							chat_id_ = v,
							from_chat_id_ = msg.chat_id_,
							message_ids_ = {[0] = id},
							disable_notification_ = 1,
							from_background_ = 1
						}, dl_cb, nil)
					end
					return send(msg.chat_id_, msg.id_, "<i>Успешно преуспели</i>")
				elseif text:match("^([Ss]end to Supergroups) (.*)") then
					local matches = text:match("^[Ss]end to Supergroups (.*)")
					local dir = redis:smembers("botBOT-IDsupergroups")
					for i, v in pairs(dir) do
						tdcli_function ({
							ID = "SendMessage",
							chat_id_ = v,
							reply_to_message_id_ = 0,
							disable_notification_ = 0,
							from_background_ = 1,
							reply_markup_ = nil,
							input_message_content_ = {
								ID = "InputMessageText",
								text_ = matches,
								disable_web_page_preview_ = 1,
								clear_draft_ = 0,
								entities_ = {},
							parse_mode_ = nil
							},
						}, dl_cb, nil)
					end
                    			return send(msg.chat_id_, msg.id_, "<i>Успешно преуспели</i>")
				elseif text:match("^([Bb]lock) (%d+)$") then
					local matches = text:match("%d+")
					rem(tonumber(matches))
					redis:sadd("botBOT-IDblockedusers",matches)
					tdcli_function ({
						ID = "BlockUser",
						user_id_ = tonumber(matches)
					}, dl_cb, nil)
					return send(msg.chat_id_, msg.id_, "<i>Целевой пользователь заблокирован</i>")
				elseif text:match("^([Uu]nblock) (%d+)$") then
					local matches = text:match("%d+")
					add(tonumber(matches))
					redis:srem("botBOT-IDblockedusers",matches)
					tdcli_function ({
						ID = "UnblockUser",
						user_id_ = tonumber(matches)
					}, dl_cb, nil)
					return send(msg.chat_id_, msg.id_, "<i>Заблокированный пользователь исправлен.</i>")
				elseif text:match('^([Ss]et name) "(.*)" (.*)') then
					local fname, lname = text:match('^[Ss]et name "(.*)" (.*)')
					tdcli_function ({
						ID = "ChangeName",
						first_name_ = fname,
						last_name_ = lname
					}, dl_cb, nil)
					return send(msg.chat_id_, msg.id_, "<i>Новое имя было успешно зарегистрировано.</i>")
				elseif text:match("^([Ss]et username) (.*)") then
					local matches = text:match("^[Ss]et username (.*)")
						tdcli_function ({
						ID = "ChangeUsername",
						username_ = tostring(matches)
						}, dl_cb, nil)
					return send(msg.chat_id_, 0, '<i>Попытка установить имя пользователя...</i>')
				elseif text:match("^([Rr]em username)$") then
					tdcli_function ({
						ID = "ChangeUsername",
						username_ = ""
					}, dl_cb, nil)
					return send(msg.chat_id_, 0, '<i>Имя пользователя успешно удалено.</i>')
				elseif text:match('^([Ss]end to me) "(.*)" (.*)') then
					local id, txt = text:match('^[Ss]end to me "(.*)" (.*)')
					send(id, 0, txt)
					return send(msg.chat_id_, msg.id_, "<i>представленный</i>")
				elseif text:match("^([Ee]cho) (.*)") then
					local matches = text:match("^echo (.*)")
					return send(msg.chat_id_, 0, matches)
				elseif text:match("^([Ii]d)$") then
					return send(msg.chat_id_, msg.id_, "<i>" .. msg.sender_user_id_ .."</i>")
				elseif text:match("^([Ll]eave) (.*)$") then
					local matches = text:match("^leave (.*)$")
					send(msg.chat_id_, msg.id_, 'Робот был исключен из группы')
					tdcli_function ({
						ID = "ChangeChatMemberStatus",
						chat_id_ = matches,
						user_id_ = bot_id,
						status_ = {ID = "ChatMemberStatusLeft"},
					}, dl_cb, nil)
					return rem(matches)
				elseif text:match("^([Aa]dd to all) (%d+)$") then
					local matches = text:match("%d+")
					local list = {redis:smembers("botBOT-IDgroups"),redis:smembers("botBOT-IDsupergroups")}
					for a, b in pairs(list) do
						for i, v in pairs(b) do
							tdcli_function ({
								ID = "AddChatMember",
								chat_id_ = v,
								user_id_ = matches,
								forward_limit_ =  50
							}, dl_cb, nil)
						end
					end
					return send(msg.chat_id_, msg.id_, "<i>Пользователь добавлен ко всем моим группам</i>")
				elseif (text:match("^([Pp]ing)$") and not msg.forward_info_)then
					return tdcli_function({
						ID = "ForwardMessages",
						chat_id_ = msg.chat_id_,
						from_chat_id_ = msg.chat_id_,
						message_ids_ = {[0] = msg.id_},
						disable_notification_ = 0,
						from_background_ = 1
					}, dl_cb, nil)
				elseif text:match("^([Hh]elp)$") then
					local txt = '<b>Tabchi orders help</b>\n\n<b>Online</b>\n<code>-help</code>\n\nhttps://t.me/tabchiro/3'
					return send(msg.chat_id_,msg.id_, txt)
				elseif tostring(msg.chat_id_):match("^-") then
					if text:match("^([Ll]eave)$") then
						rem(msg.chat_id_)
						return tdcli_function ({
							ID = "ChangeChatMemberStatus",
							chat_id_ = msg.chat_id_,
							user_id_ = bot_id,
							status_ = {ID = "ChatMemberStatusLeft"},
						}, dl_cb, nil)
					elseif text:match("^([Aa]dd all contacts)$") then
						tdcli_function({
							ID = "SearchContacts",
							query_ = nil,
							limit_ = 999999999
						},function(i, sami)
							local users, count = redis:smembers("botBOT-IDusers"), sami.total_count_
							for n=0, tonumber(count) - 1 do
								tdcli_function ({
									ID = "AddChatMember",
									chat_id_ = i.chat_id,
									user_id_ = sami.users_[n].id_,
									forward_limit_ = 50
								},  dl_cb, nil)
							end
							for n=1, #users do
								tdcli_function ({
									ID = "AddChatMember",
									chat_id_ = i.chat_id,
									user_id_ = users[n],
									forward_limit_ = 50
								},  dl_cb, nil)
							end
						end, {chat_id=msg.chat_id_})
						return send(msg.chat_id_, msg.id_, "<i>Добавление контактов в группу ...</i>")
					end
				end
			end
			if redis:sismember("botBOT-IDanswerslist", text) then
				if redis:get("botBOT-IDautoanswer") then
					if msg.sender_user_id_ ~= bot_id then
						local answer = redis:hget("botBOT-IDanswers", text)
						send(msg.chat_id_, 0, answer)
					end
				end
			end
		elseif (msg.content_.ID == "MessageContact" and redis:get("botBOT-IDsavecontacts")) then
			local id = msg.content_.contact_.user_id_
			if not redis:sismember("botBOT-IDaddedcontacts",id) then
				redis:sadd("botBOT-IDaddedcontacts",id)
				local first = msg.content_.contact_.first_name_ or "-"
				local last = msg.content_.contact_.last_name_ or "-"
				local phone = msg.content_.contact_.phone_number_
				local id = msg.content_.contact_.user_id_
				tdcli_function ({
					ID = "ImportContacts",
					contacts_ = {[0] = {
							phone_number_ = tostring(phone),
							first_name_ = tostring(first),
							last_name_ = tostring(last),
							user_id_ = id
						},
					},
				}, dl_cb, nil)
				if redis:get("botBOT-IDaddcontact") and msg.sender_user_id_ ~= bot_id then
					local fname = redis:get("botBOT-IDfname")
					local lnasme = redis:get("botBOT-IDlname") or ""
					local num = redis:get("botBOT-IDnum")
					tdcli_function ({
						ID = "SendMessage",
						chat_id_ = msg.chat_id_,
						reply_to_message_id_ = msg.id_,
						disable_notification_ = 1,
						from_background_ = 1,
						reply_markup_ = nil,
						input_message_content_ = {
							ID = "InputMessageContact",
							contact_ = {
								ID = "Contact",
								phone_number_ = num,
								first_name_ = fname,
								last_name_ = lname,
								user_id_ = bot_id
							},
						},
					}, dl_cb, nil)
				end
			end
			if redis:get("botBOT-IDaddmsg") then
				local answer = redis:get("botBOT-IDaddmsgtext") or "Addi [addi bia channels @etehad_arazel]"
				send(msg.chat_id_, msg.id_, answer)
			end
		elseif msg.content_.ID == "MessageChatDeleteMember" and msg.content_.id_ == bot_id then
			return rem(msg.chat_id_)
		elseif (msg.content_.caption_ and redis:get("botBOT-IDlink"))then
			find_link(msg.content_.caption_)
		end
		if redis:get("botBOT-IDmarkread") then
			tdcli_function ({
				ID = "ViewMessages",
				chat_id_ = msg.chat_id_,
				message_ids_ = {[0] = msg.id_}
			}, dl_cb, nil)
		end
	elseif data.ID == "UpdateOption" and data.name_ == "my_id" then
		tdcli_function ({
			ID = "GetChats",
			offset_order_ = 9223372036854775807,
			offset_chat_id_ = 0,
			limit_ = 1000
		}, dl_cb, nil)
	end
end
