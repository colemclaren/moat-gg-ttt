DROP PROCEDURE IF EXISTS createUserInfo;
DELIMITER $$
CREATE PROCEDURE createUserInfo(in stid text, in stname text charset utf8mb4, in ipaddr text, in ostime bigint)
BEGIN
	set @Count = (SELECT COUNT(*) AS Cnt FROM player WHERE `SteamID`=stid);
	if (@Count = 0) then
		insert into player (`SteamID`, `SteamName`, `FirstJoined`, `Vars`) VALUES (stid, stname, ostime, null);
		insert into player_iplog (`SteamID`, `Address`, `LastSeen`) VALUES(stid, ipaddr, -1);
		select 1 as Created;
	else
		select 0 as Created;
	end if;
END; $$
DELIMITER ;

DROP PROCEDURE IF EXISTS selectUserInfo;
DELIMITER $$
CREATE PROCEDURE selectUserInfo(in stid text)
BEGIN
	SELECT player.SteamName, player.Rank, player.TimePlayed, player.FirstJoined, player.Vars, player_iplog.Address, player_iplog.LastSeen FROM player, player_iplog WHERE player.SteamID=stid AND player_iplog.SteamID=stid ORDER BY LastSeen DESC LIMIT 1;
END; $$
DELIMITER ;

DROP PROCEDURE IF EXISTS updateUserInfo;
DELIMITER $$
CREATE PROCEDURE updateUserInfo(in stid text, in steamname text, in ipaddr text, in ostime bigint)
BEGIN
	update player set `SteamName` = steamname where `SteamID` = stid;
	delete from player_iplog where `SteamID` = stid and `Address` = ipaddr;
	INSERT INTO player_iplog (`SteamID`, `Address`, `LastSeen`) VALUES (stid, ipaddr, ostime);
END; $$
DELIMITER ;

DROP PROCEDURE IF EXISTS removeItem;
DELIMITER $$
CREATE PROCEDURE removeItem(in cid int)
BEGIN
	update mg_items set ownerid = 0 where id = cid;
END; $$
DELIMITER ;

DROP PROCEDURE IF EXISTS transferItem;
DELIMITER $$
CREATE PROCEDURE transferItem(in cid int, in owner bigint)
BEGIN
	update mg_items set ownerid = owner where id = cid;
END; $$
DELIMITER ;

DROP PROCEDURE IF EXISTS updateItemStat;
DELIMITER $$
CREATE PROCEDURE updateItemStat(in cid int, in stat char(1), in newval float)
BEGIN
	update mg_itemstats set statid = newval where weaponid = cid;
END; $$
DELIMITER ;

DROP PROCEDURE IF EXISTS insertItemName;
DELIMITER $$
CREATE PROCEDURE insertItemName(in uid int unsigned, in nstr varchar(32))
BEGIN
	insert into moat_inv_items_names (weaponid, nickname) values (uid, nstr);
	select uid as cid;
END; $$
DELIMITER ;

DROP PROCEDURE IF EXISTS selectStats;
DELIMITER $$
CREATE PROCEDURE selectStats(in steamid bigint)
BEGIN
	select var, val from mg_players where id = steamid;
END; $$
DELIMITER ;

DROP PROCEDURE IF EXISTS selectStat;
DELIMITER $$
CREATE PROCEDURE selectStat(in steamid bigint, in stat char(1))
BEGIN
	select var, val from mg_players where id = steamid and var = stat;
END; $$
DELIMITER ;

DROP PROCEDURE IF EXISTS saveStat;
DELIMITER $$
CREATE PROCEDURE saveStat(in `steamid` bigint, in `stat` CHAR(1), in `num` INT)
BEGIN
	insert into mg_players (id, var, val) values (steamid, stat, num) on duplicate key update val = num;
END; $$
DELIMITER ;

DROP PROCEDURE IF EXISTS getSteamIDFromDiscordTag;
DELIMITER $$
CREATE PROCEDURE getSteamIDFromDiscordTag(in tag varchar(255))
BEGIN
	SET @mid = (SELECT member_id FROM memberssocialinfo_sites WHERE discord LIKE tag LIMIT 1);
	if (FOUND_ROWS() = 0) then
		select 0 as steamid;
	else
		select steamid FROM core_members WHERE member_id LIKE @mid LIMIT 1;
	end if;
END; $$
DELIMITER ;

DROP PROCEDURE IF EXISTS selectRconCommands;
DELIMITER $$
CREATE PROCEDURE selectRconCommands(in `srvr` varchar(255))
BEGIN
	select id, staff_steamid, staff_rank, staff_name, command, args, steamid from rcon_commands as rc inner join rcon_queue as rq on rc.id = rq.cmdid where rq.server = srvr;
END; $$
DELIMITER ;

DROP PROCEDURE IF EXISTS insertRconCommand;
DELIMITER $$
CREATE PROCEDURE insertRconCommand(in `sid` varchar(30), in `srank` tinytext, in `sname` text, in `cmd` text, in `srvr` varchar(255), in `arg` text, in `sido` varchar(30))
BEGIN
	insert into rcon_commands (staff_steamid, staff_rank, staff_name, `server`, command, args, steamid) values (sid, srank, sname, srvr, cmd, arg, sido);

	set @cid = LAST_INSERT_ID();
	if (srvr = "*") then
		set @num = (SELECT COUNT(*) FROM player_servers);
		while @num > 0 do
			select ip, port into @i, @p from player_servers where id = @num;
			insert into rcon_queue (cmdid, server) values (@cid, concat(@i, ":", @p));
			set @num = @num - 1;
		end while;
	else
		insert into rcon_queue (cmdid, server) values (@cid, srvr);
	end if;

	select @cid as cmd_id;
END; $$
DELIMITER ;

DROP PROCEDURE IF EXISTS insertRconCommand;
DELIMITER $$
CREATE PROCEDURE insertRconCommand(in `sid` varchar(30), in `srank` tinytext, in `sname` text, in `cmd` text, in `srvr` varchar(255), in `arg` text, in `sido` varchar(30))
BEGIN
	insert into rcon_commands (staff_steamid, staff_rank, staff_name, `server`, command, args, steamid) values (sid, srank, sname, srvr, cmd, arg, sido);

	set @cid = LAST_INSERT_ID();
	if (srvr = "*") then
		set @num = (SELECT COUNT(*) FROM player_servers);
		while @num > 0 do
			select ip, port into @i, @p from player_servers where id = @num;
			insert into rcon_queue (cmdid, server) values (@cid, concat(@i, ":", @p));
			set @num = @num - 1;
		end while;
	else
		insert into rcon_queue (cmdid, server) values (@cid, srvr);
	end if;

	select @cid as cmd_id;
END; $$
DELIMITER ;

DROP PROCEDURE IF EXISTS selectContract;
DELIMITER $$
CREATE PROCEDURE selectContract(in `id` varchar(255))
BEGIN
	SELECT score as myscore, steamid, (SELECT COUNT(*) FROM moat_contractplayers_v2 WHERE score >= myscore) AS position, (SELECT COUNT(steamid) FROM moat_contractplayers_v2) AS players FROM moat_contractplayers_v2 WHERE steamid = id;
END; $$
DELIMITER ;

DROP PROCEDURE IF EXISTS removeRconCommands;
DELIMITER $$
CREATE PROCEDURE removeRconCommands(in srvr varchar(255))
BEGIN
	delete from rcon_queue where server = srvr;
END; $$
DELIMITER ;

DROP PROCEDURE IF EXISTS selectContracts;
DELIMITER $$
CREATE PROCEDURE selectContracts(in `ip` varchar(255))
BEGIN
	SELECT `moat_contractplayers`.`score` as myscore, `moat_contractplayers`.`steamid`, (SELECT COUNT(*) FROM `moat_contractplayers` WHERE score >= myscore) AS position, (SELECT COUNT(steamid) FROM moat_contractplayers) AS players FROM `moat_contractplayers` INNER JOin `player_sessions` ON (`moat_contractplayers`.`steamid` = `player_sessions`.`steamid64` AND `player_sessions`.`server` = ip) ORDER BY score;
END; $$
DELIMITER ;

DROP PROCEDURE IF EXISTS insertPayload;
DELIMITER $$
CREATE PROCEDURE insertPayload(in `pl` mediumtext)
BEGIN
	INSERT INTO github_payloads (payload) VALUES (pl);
	SELECT LAST_INSERT_ID() AS pid;
END; $$
DELIMITER ;

DROP PROCEDURE IF EXISTS updateGithubAuthors;
DELIMITER $$
CREATE PROCEDURE updateGithubAuthors(in `puid` varchar(255), in `pname` text, in `pemail` text, in `pnode_id` text, in `pavatar_url` text, in `pgithub_url` text)
BEGIN
	INSERT INTO github_authors (uid, name, email, node_id, avatar_url, github_url) VALUES (puid, pname, pemail, pnode_id, pavatar_url, pgithub_url) ON DUPLICATE KEY UPDATE name = pname, email = pemail, avatar_url = pavatar_url, github_url = pgithub_url;
	SELECT id FROM github_authors WHERE uid = puid;
END; $$
DELIMITER ;

DROP PROCEDURE IF EXISTS selectInventory;
DELIMITER $$
CREATE PROCEDURE selectInventory(in `steamid64` bigint)
BEGIN
	SELECT id, itemid, slotid, classname FROM mg_items WHERE ownerid = steamid64;
	SELECT id, statid, value FROM mg_itemstats as ws INNER JOin mg_items as wd ON ws.weaponid = wd.id WHERE wd.ownerid = steamid64;
	SELECT id, talentid, required, modification, value FROM mg_itemtalents as wt INNER JOin mg_items as wd ON wt.weaponid = wd.id WHERE wd.ownerid = steamid64 ORDER BY modification;
	SELECT id, nickname FROM mg_itemnames as wn INNER JOin mg_items as wd ON wn.weaponid = wd.id WHERE wd.ownerid = steamid64;
	SELECT id, type, paintid FROM mg_itempaints as wp INNER JOin mg_items as wd ON wp.weaponid = wd.id WHERE wd.ownerid = steamid64;
END; $$
DELIMITER ;

CREATE TABLE IF NOT EXISTS `core_dev_ttt` (
	`steamid` varchar(100) NOT NULL,
	`max_slots` int(255) NOT NULL,
	`credits` mediumtext NOT NULL,
	`l_slot1` mediumtext DEFAULT NULL,
	`l_slot2` mediumtext DEFAULT NULL,
	`l_slot3` mediumtext DEFAULT NULL,
	`l_slot4` mediumtext DEFAULT NULL,
	`l_slot5` mediumtext DEFAULT NULL,
	`l_slot6` mediumtext DEFAULT NULL,
	`l_slot7` mediumtext DEFAULT NULL,
	`l_slot8` mediumtext DEFAULT NULL,
	`l_slot9` mediumtext DEFAULT NULL,
	`l_slot10` mediumtext DEFAULT NULL,
	`inventory` longtext NOT NULL,
	PRIMARY KEY (`steamid`)
);

CREATE TABLE IF NOT EXISTS `ac_hash_track_real` (
	`steamid` bigint(20) unsigned NOT NULL,
	`hash` binary(64) NOT NULL,
	PRIMARY KEY (`steamid`,`hash`)
);

CREATE TABLE IF NOT EXISTS `ac_hashes_real` (
	`hash` binary(64) NOT NULL,
	`triggers` int(10) unsigned NOT NULL DEFAULT 1,
	PRIMARY KEY (`hash`)
);

CREATE TABLE IF NOT EXISTS `bounties_current` (
	`ID` int(11) NOT NULL AUTO_INCREMENT,
	`bounties` text NOT NULL,
	PRIMARY KEY (`ID`)
);

CREATE TABLE IF NOT EXISTS `bounties_players` (
	`steamid` varchar(100) NOT NULL,
	`score` text NOT NULL,
	PRIMARY KEY (`steamid`)
);

CREATE TABLE IF NOT EXISTS `core_members` (
	`member_id` mediumint(8) NOT NULL AUTO_INCREMENT,
	`name` varchar(255) NOT NULL DEFAULT '',
	`member_group_id` smallint(3) NOT NULL DEFAULT 0,
	`email` varchar(150) NOT NULL DEFAULT '',
	`joined` int(10) NOT NULL DEFAULT 0,
	`ip_address` varchar(46) NOT NULL DEFAULT '',
	`skin` smallint(5) DEFAULT NULL,
	`warn_level` int(10) DEFAULT NULL,
	`warn_lastwarn` int(10) NOT NULL DEFAULT 0,
	`language` mediumint(4) DEFAULT NULL,
	`restrict_post` int(10) NOT NULL DEFAULT 0,
	`bday_day` int(2) DEFAULT NULL,
	`bday_month` int(2) DEFAULT NULL,
	`bday_year` int(4) DEFAULT NULL,
	`msg_count_new` int(2) NOT NULL DEFAULT 0,
	`msg_count_total` int(3) NOT NULL DEFAULT 0,
	`msg_count_reset` int(1) NOT NULL DEFAULT 0,
	`msg_show_notification` int(1) NOT NULL DEFAULT 0,
	`last_visit` int(10) DEFAULT 0,
	`last_activity` int(10) DEFAULT 0,
	`mod_posts` int(10) NOT NULL DEFAULT 0,
	`auto_track` varchar(255) DEFAULT '0',
	`temp_ban` int(10) DEFAULT 0,
	`mgroup_others` varchar(245) NOT NULL DEFAULT '',
	`member_login_key_expire` int(10) NOT NULL DEFAULT 0,
	`members_seo_name` varchar(255) NOT NULL DEFAULT '',
	`members_cache` mediumtext DEFAULT NULL,
	`failed_logins` text DEFAULT NULL,
	`failed_login_count` smallint(3) NOT NULL DEFAULT 0,
	`members_profile_views` int(10) unsigned NOT NULL DEFAULT 0,
	`members_pass_hash` varchar(255) DEFAULT NULL,
	`members_pass_salt` varchar(22) DEFAULT NULL,
	`members_bitoptions` int(10) unsigned NOT NULL DEFAULT 0,
	`fb_uid` bigint(20) unsigned NOT NULL DEFAULT 0,
	`members_day_posts` varchar(32) NOT NULL DEFAULT '0,0',
	`live_id` varchar(32) DEFAULT NULL,
	`twitter_id` varchar(255) NOT NULL DEFAULT '',
	`twitter_token` varchar(255) NOT NULL DEFAULT '',
	`twitter_secret` varchar(255) NOT NULL DEFAULT '',
	`notification_cnt` mediumint(9) NOT NULL DEFAULT 0,
	`fb_token` text DEFAULT NULL,
	`ipsconnect_id` int(10) NOT NULL DEFAULT 0,
	`google_id` varchar(50) DEFAULT NULL,
	`linkedin_id` varchar(32) DEFAULT NULL,
	`pp_last_visitors` text DEFAULT NULL,
	`pp_main_photo` text DEFAULT NULL,
	`pp_main_width` int(5) DEFAULT NULL,
	`pp_main_height` int(5) DEFAULT NULL,
	`pp_thumb_photo` text DEFAULT NULL,
	`pp_thumb_width` int(5) DEFAULT NULL,
	`pp_thumb_height` int(5) DEFAULT NULL,
	`pp_setting_count_comments` int(2) DEFAULT NULL,
	`pp_reputation_points` int(10) DEFAULT NULL,
	`pp_photo_type` varchar(20) DEFAULT NULL,
	`signature` text DEFAULT NULL,
	`pconversation_filters` text DEFAULT NULL,
	`fb_photo` text DEFAULT NULL,
	`fb_photo_thumb` text DEFAULT NULL,
	`fb_bwoptions` int(10) DEFAULT NULL,
	`tc_last_sid_import` varchar(50) DEFAULT NULL,
	`tc_photo` text DEFAULT NULL,
	`tc_bwoptions` int(10) DEFAULT NULL,
	`pp_customization` mediumtext DEFAULT NULL,
	`timezone` varchar(64) DEFAULT NULL,
	`pp_cover_photo` varchar(255) NOT NULL DEFAULT '',
	`profilesync` text DEFAULT NULL,
	`profilesync_lastsync` int(10) NOT NULL DEFAULT 0 COMMENT 'Indicates the last time any profile sync service was ran',
	`google_token` text DEFAULT NULL,
	`linkedin_token` text DEFAULT NULL,
	`live_token` text DEFAULT NULL,
	`allow_admin_mails` bit(1) DEFAULT b'0',
	`members_bitoptions2` int(10) unsigned NOT NULL DEFAULT 0,
	`create_menu` text DEFAULT NULL COMMENT 'Cached contents of the "Create" drop down menu.',
	`ipsconnect_revalidate_url` text DEFAULT NULL,
	`members_disable_pm` tinyint(1) unsigned NOT NULL DEFAULT 0 COMMENT '0 - not disabled, 1 - disabled, member can re-enable, 2 - disabled',
	`marked_site_read` int(10) unsigned DEFAULT 0,
	`pp_cover_offset` int(10) NOT NULL DEFAULT 0,
	`acp_skin` smallint(6) DEFAULT NULL,
	`acp_language` mediumint(9) DEFAULT NULL,
	`member_title` varchar(64) DEFAULT NULL,
	`member_posts` mediumint(7) NOT NULL DEFAULT 0,
	`member_last_post` int(10) DEFAULT NULL,
	`member_streams` text DEFAULT NULL,
	`photo_last_update` int(10) DEFAULT NULL,
	`steamid` varchar(17) DEFAULT NULL,
	`kuzi_song_path` varchar(255) DEFAULT '' COMMENT 'Profile song path.',
	`failed_mfa_attempts` smallint(3) unsigned DEFAULT 0 COMMENT 'Number of times tried and failed MFA',
	`unlucky_enable` int(1) DEFAULT 0,
	`unlucky_url` varchar(255) DEFAULT '',
	`mfa_details` text DEFAULT NULL,
	`permission_array` text DEFAULT NULL COMMENT 'A cache of the clubs and social groups that the member is in',
	`discord_id` varchar(20) DEFAULT NULL,
	`discord_name` varchar(50) DEFAULT NULL,
	`account_closed` tinyint(1) unsigned DEFAULT 0,
	`account_closed_reason` text DEFAULT NULL,
	`autoreplypm_on` tinyint(1) DEFAULT 0,
	`autoreplypm_text` text DEFAULT NULL,
	`nbcontentratings_positive` int(10) unsigned DEFAULT NULL,
	`nbcontentratings_negative` int(10) unsigned DEFAULT NULL,
	`nbcontentratings_neutral` int(10) unsigned DEFAULT NULL,
	`tm_member_tracked` tinyint(1) NOT NULL DEFAULT 0,
	`tm_member_tracked_deadline` int(10) NOT NULL DEFAULT 0,
	`tm_member_tracked_log_entries` int(10) NOT NULL DEFAULT 0,
	`tm_member_tracked_actions` text DEFAULT NULL,
	`completed` bit(1) NOT NULL DEFAULT b'0' COMMENT 'Whether the account is completed or not',
	`conv_password` varchar(255) DEFAULT NULL,
	`conv_password_extra` varchar(255) DEFAULT NULL,
	`membermap_location_synced` tinyint(1) DEFAULT 0,
	`cm_credits` text DEFAULT NULL,
	`cm_no_sev` tinyint(1) DEFAULT 0,
	`cm_return_group` smallint(3) DEFAULT 0,
	`idm_block_submissions` tinyint(1) unsigned DEFAULT 0 COMMENT 'Blocked from submitting Downloads files?',
	PRIMARY KEY (`member_id`),
	UNIQUE KEY `discord_id` (`discord_id`),
	KEY `bday_day` (`bday_day`),
	KEY `bday_month` (`bday_month`),
	KEY `members_bitoptions` (`members_bitoptions`),
	KEY `ip_address` (`ip_address`),
	KEY `failed_login_count` (`failed_login_count`),
	KEY `joined` (`joined`),
	KEY `fb_uid` (`fb_uid`),
	KEY `twitter_id` (`twitter_id`(191)),
	KEY `email` (`email`),
	KEY `member_groups` (`member_group_id`,`mgroup_others`(188)),
	KEY `google_id` (`google_id`),
	KEY `linkedin_id` (`linkedin_id`),
	KEY `mgroup` (`member_id`,`member_group_id`),
	KEY `allow_admin_mails` (`allow_admin_mails`),
	KEY `name_index` (`name`(191)),
	KEY `ipsconnect_id` (`ipsconnect_id`),
	KEY `mod_posts` (`mod_posts`),
	KEY `photo_last_update` (`photo_last_update`),
	KEY `steamid` (`steamid`),
	KEY `last_activity` (`last_activity`),
	KEY `completed` (`completed`,`temp_ban`),
	KEY `profilesync` (`profilesync_lastsync`,`profilesync`(150))
);

CREATE TABLE IF NOT EXISTS `github_authors` (
	`id` int(11) NOT NULL AUTO_INCREMENT,
	`uid` varchar(255) NOT NULL,
	`name` mediumtext NOT NULL,
	`email` mediumtext NOT NULL,
	`node_id` mediumtext DEFAULT NULL,
	`avatar_url` mediumtext DEFAULT NULL,
	`github_url` mediumtext DEFAULT NULL,
	`moat_url` mediumtext DEFAULT NULL,
	`steam_url` mediumtext DEFAULT NULL,
	`bio` text DEFAULT NULL,
	`jobs` int(1) DEFAULT NULL,
	`hide` tinyint(1) DEFAULT NULL,
	PRIMARY KEY (`uid`),
	UNIQUE KEY `id` (`id`,`uid`) USING BTREE
);

CREATE TABLE IF NOT EXISTS `github_commits` (
	`id` int(11) NOT NULL AUTO_INCREMENT,
	`sha` varchar(40) NOT NULL,
	`date` datetime NOT NULL,
	`repo_id` mediumtext NOT NULL,
	`author_id` int(11) NOT NULL,
	`summary` mediumtext NOT NULL,
	`type` mediumtext DEFAULT NULL,
	`branch` mediumtext NOT NULL,
	`files_modified` int(11) NOT NULL,
	`payload` int(11) NOT NULL,
	`hide` tinyint(1) DEFAULT NULL,
	`lines_added` int(11) DEFAULT NULL,
	`lines_removed` int(11) DEFAULT NULL,
	PRIMARY KEY (`sha`),
	UNIQUE KEY `id` (`id`) USING BTREE
);

CREATE TABLE IF NOT EXISTS `github_payloads` (
	`pid` int(11) NOT NULL AUTO_INCREMENT,
	`time` timestamp DEFAULT CURRENT_TIMESTAMP,
	`payload` longtext NOT NULL,
	PRIMARY KEY (`pid`)
);

CREATE TABLE IF NOT EXISTS `gmod_owners` (
	`id` int(11) unsigned NOT NULL AUTO_INCREMENT,
	`date` varchar(255) NOT NULL,
	`start` int(11) NOT NULL,
	`end` int(11) NOT NULL,
	`difference` int(11) NOT NULL,
	PRIMARY KEY (`id`)
);

CREATE TABLE IF NOT EXISTS `lola_error_reports` (
	`id` int(11) NOT NULL,
	`messageid` varchar(30) NOT NULL,
	PRIMARY KEY (`id`)
);

CREATE TABLE IF NOT EXISTS `mg_items` (
	`id` int(10) unsigned NOT NULL AUTO_INCREMENT,
	`itemid` int(10) unsigned NOT NULL,
	`ownerid` bigint(20) unsigned NOT NULL,
	`slotid` int(10) DEFAULT NULL,
	`classname` varchar(32) DEFAULT NULL,
	`createdat` timestamp DEFAULT CURRENT_TIMESTAMP,
	`updatedat` timestamp DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
	PRIMARY KEY (`id`),
	KEY `ownerid` (`ownerid`)
);

CREATE TABLE IF NOT EXISTS `mg_itemnames` (
	`weaponid` int(10) unsigned NOT NULL,
	`nickname` varchar(32) NOT NULL,
	`updatedat` timestamp DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
	PRIMARY KEY (`weaponid`),
	CONSTRAINT `fk_mg_itemnames_mg_items` FOREIGN KEY (`weaponid`) REFERENCES `mg_items` (`id`) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS `mg_itempaints` (
	`weaponid` int(10) unsigned NOT NULL,
	`type` smallint(5) unsigned NOT NULL,
	`paintid` smallint(5) unsigned NOT NULL,
	`updatedat` timestamp DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
	PRIMARY KEY (`weaponid`,`type`),
	KEY `weaponid` (`weaponid`),
	CONSTRAINT `fk_mg_itempaints_mg_items` FOREIGN KEY (`weaponid`) REFERENCES `mg_items` (`id`) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS `mg_itemstats` (
	`weaponid` int(10) unsigned NOT NULL,
	`statid` char(1) NOT NULL,
	`value` float NOT NULL,
	`updatedat` timestamp DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
	PRIMARY KEY (`weaponid`,`statid`),
	KEY `weaponid` (`weaponid`),
	CONSTRAINT `fk_mg_itemstats_mg_items` FOREIGN KEY (`weaponid`) REFERENCES `mg_items` (`id`) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS `mg_itemtalents` (
	`weaponid` int(10) unsigned NOT NULL,
	`talentid` smallint(5) unsigned NOT NULL,
	`required` smallint(5) unsigned DEFAULT NULL,
	`modification` tinyint(3) unsigned NOT NULL,
	`value` float NOT NULL,
	`updatedat` timestamp DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
	KEY `weaponid` (`weaponid`),
	CONSTRAINT `fk_mg_itemtalents_mg_items` FOREIGN KEY (`weaponid`) REFERENCES `mg_items` (`id`) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS `mg_players` (
	`id` bigint(20) unsigned NOT NULL,
	`var` char(1) NOT NULL,
	`val` int(10) unsigned NOT NULL,
	`createdat` timestamp DEFAULT CURRENT_TIMESTAMP,
	`updatedat` timestamp DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
	PRIMARY KEY (`id`,`var`),
	UNIQUE KEY `id` (`id`,`var`) USING BTREE
);

CREATE TABLE IF NOT EXISTS `moat_alt` (
	`steamid64` bigint(20) NOT NULL,
	`fp1` int(11) NOT NULL,
	`fp2` bigint(20) NOT NULL,
	`fp3` bigint(20) NOT NULL,
	PRIMARY KEY (`steamid64`),
	KEY `fp1` (`fp1`),
	KEY `fp2` (`fp2`),
	KEY `fp3` (`fp3`)
);

CREATE TABLE IF NOT EXISTS `moat_battlepass` (
	`steamid` varchar(32) NOT NULL,
	`tier` int(11) DEFAULT NULL,
	`xp` int(11) DEFAULT NULL,
	PRIMARY KEY (`steamid`)
);

CREATE TABLE IF NOT EXISTS `moat_comps` (
	`ID` int(11) NOT NULL AUTO_INCREMENT,
	`time` int(11) NOT NULL,
	`steamid` varchar(255) NOT NULL,
	`admin` mediumtext NOT NULL,
	`link` mediumtext NOT NULL,
	`ic` mediumtext NOT NULL,
	`ec` mediumtext NOT NULL,
	`sc` mediumtext DEFAULT NULL,
	`item` mediumtext NOT NULL,
	`class` mediumtext NOT NULL,
	`talent1` mediumtext NOT NULL,
	`talent2` mediumtext NOT NULL,
	`talent3` mediumtext NOT NULL,
	`talent4` mediumtext NOT NULL,
	`comment` mediumtext NOT NULL,
	`approved` mediumtext NOT NULL,
	PRIMARY KEY (`ID`)
);

CREATE TABLE IF NOT EXISTS `moat_contract_cache` (
	`id` int(10) unsigned NOT NULL AUTO_INCREMENT,
	`wpns` int(10) unsigned DEFAULT NULL,
	`kills` int(10) unsigned DEFAULT NULL,
	`last_updated` timestamp DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
	PRIMARY KEY (`id`)
);

CREATE TABLE IF NOT EXISTS `moat_contractplayers` (
	`steamid` varchar(100) NOT NULL,
	`score` int(11) NOT NULL,
	PRIMARY KEY (`steamid`)
);

CREATE TABLE IF NOT EXISTS `moat_contractplayers_v2` (
	`steamid` varchar(100) NOT NULL,
	`score` int(11) NOT NULL,
	PRIMARY KEY (`steamid`)
);

CREATE TABLE IF NOT EXISTS `moat_contractrig` (
	`contract` varchar(100) NOT NULL,
	PRIMARY KEY (`contract`)
);

CREATE TABLE IF NOT EXISTS `moat_contracts` (
	`ID` int(11) NOT NULL AUTO_INCREMENT,
	`contract` varchar(255) NOT NULL,
	`start_time` int(11) NOT NULL,
	`active` int(11) NOT NULL,
	`refresh_next` int(11) DEFAULT NULL,
	`updating_server` varchar(32) DEFAULT NULL,
	PRIMARY KEY (`ID`),
	KEY `active` (`active`),
	KEY `refresh_next` (`refresh_next`)
);

CREATE TABLE IF NOT EXISTS `moat_contracts_revamped` (
	`ID` int(11) NOT NULL AUTO_INCREMENT,
	`contract` varchar(255) NOT NULL,
	`start_time` timestamp DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
	`updating_server` varchar(32) DEFAULT NULL,
	PRIMARY KEY (`ID`)
);

CREATE TABLE IF NOT EXISTS `moat_contracts_test` (
	`ID` int(11) NOT NULL AUTO_INCREMENT,
	`contract` varchar(255) NOT NULL,
	`start_time` int(11) NOT NULL,
	`active` int(11) NOT NULL,
	`refresh_next` int(11) DEFAULT NULL,
	`updating_server` varchar(32) DEFAULT NULL,
	PRIMARY KEY (`ID`)
);

CREATE TABLE IF NOT EXISTS `moat_contracts_v2` (
	`ID` int(11) NOT NULL AUTO_INCREMENT,
	`contract` varchar(64) NOT NULL,
	`start_time` timestamp NULL DEFAULT NULL,
	`contract_id` int(11) NOT NULL,
	`updating_server` varchar(32) DEFAULT NULL,
	PRIMARY KEY (`ID`)
);

CREATE TABLE IF NOT EXISTS `moat_contractwinners` (
	`steamid` varchar(32) NOT NULL,
	`place` int(11) NOT NULL,
	PRIMARY KEY (`steamid`)
);

CREATE TABLE IF NOT EXISTS `moat_contractwinners_v2` (
	`steamid` bigint(20) unsigned NOT NULL,
	`place` int(10) unsigned NOT NULL,
	PRIMARY KEY (`steamid`)
);

CREATE TABLE IF NOT EXISTS `moat_discord` (
	`steamid` varchar(32) NOT NULL,
	`oauth` mediumtext NOT NULL,
	`date` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
	PRIMARY KEY (`steamid`)
);

CREATE TABLE IF NOT EXISTS `moat_errors` (
	`id` int(11) NOT NULL AUTO_INCREMENT,
	`error` mediumtext NOT NULL,
	`serverip` varchar(255) NOT NULL,
	`realm` tinyint(1) NOT NULL,
	`stack` mediumtext DEFAULT NULL,
	`steamid` varchar(20) DEFAULT NULL,
	`date` timestamp DEFAULT CURRENT_TIMESTAMP,
	PRIMARY KEY (`id`)
);

CREATE TABLE IF NOT EXISTS `moat_feedback` (
	`vote` int(11) NOT NULL,
	`map` varchar(100) NOT NULL,
	`steamid` varchar(32) NOT NULL,
	KEY `vote` (`vote`),
	KEY `map` (`map`),
	KEY `steamid` (`steamid`)
);

CREATE TABLE IF NOT EXISTS `moat_forums` (
	`id` varchar(30) NOT NULL DEFAULT '',
	`num` int(11) DEFAULT NULL,
	PRIMARY KEY (`id`)
);

CREATE TABLE IF NOT EXISTS `moat_gchat` (
	`ID` int(11) NOT NULL AUTO_INCREMENT,
	`steamid` varchar(255) NOT NULL,
	`time` int(11) NOT NULL,
	`name` varchar(255) CHARACTER SET utf8mb4 NOT NULL,
	`msg` mediumtext NOT NULL,
	PRIMARY KEY (`ID`),
	KEY `time` (`time`)
);

CREATE TABLE IF NOT EXISTS `moat_inv_items` (
	`id` int(10) unsigned NOT NULL AUTO_INCREMENT,
	`itemid` int(10) unsigned NOT NULL,
	`ownerid` bigint(20) unsigned NOT NULL,
	`slotid` int(10) DEFAULT NULL,
	`classname` varchar(32) DEFAULT NULL,
	`createdat` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
	`updatedat` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
	PRIMARY KEY (`id`),
	KEY `ownerid` (`ownerid`)
);

CREATE TABLE IF NOT EXISTS `moat_inv_items_names` (
	`weaponid` int(10) unsigned NOT NULL,
	`nickname` varchar(32) NOT NULL,
	`changerid` bigint(20) unsigned NOT NULL,
	`updatedat` timestamp DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS `moat_inv_items_paints` (
	`weaponid` int(10) unsigned NOT NULL,
	`type` smallint(5) unsigned NOT NULL,
	`paintid` smallint(5) unsigned NOT NULL,
	`updatedat` timestamp DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS `moat_inv_items_talents` (
	`weaponid` int(10) unsigned NOT NULL,
	`talentid` smallint(5) unsigned NOT NULL,
	`required` smallint(5) unsigned DEFAULT NULL,
	`modification` tinyint(3) unsigned NOT NULL,
	`value` float NOT NULL,
	`updatedat` timestamp DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
	KEY `weaponid` (`weaponid`),
	CONSTRAINT `fk_moat_inv_items_talents_moat_inv_items` FOREIGN KEY (`weaponid`) REFERENCES `moat_inv_items` (`id`) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS `moat_inv_players` (
	`id` bigint(20) unsigned NOT NULL,
	`var` char(1) NOT NULL,
	`val` int(10) unsigned NOT NULL,
	`createdat` timestamp DEFAULT CURRENT_TIMESTAMP,
	`updatedat` timestamp DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
	PRIMARY KEY (`id`,`var`),
	UNIQUE KEY `id` (`id`,`var`) USING BTREE
);

CREATE TABLE IF NOT EXISTS `moat_inventories` (
	`steamid` varchar(100) NOT NULL,
	`max_slots` int(255) NOT NULL,
	`credits` mediumtext NOT NULL,
	`l_slot1` mediumtext DEFAULT NULL,
	`l_slot2` mediumtext DEFAULT NULL,
	`l_slot3` mediumtext DEFAULT NULL,
	`l_slot4` mediumtext DEFAULT NULL,
	`l_slot5` mediumtext DEFAULT NULL,
	`l_slot6` mediumtext DEFAULT NULL,
	`l_slot7` mediumtext DEFAULT NULL,
	`l_slot8` mediumtext DEFAULT NULL,
	`l_slot9` mediumtext DEFAULT NULL,
	`l_slot10` mediumtext DEFAULT NULL,
	`inventory` longtext NOT NULL,
	PRIMARY KEY (`steamid`)
);

CREATE TABLE IF NOT EXISTS `moat_inventories_dev` (
	`steamid` varchar(255) NOT NULL,
	`max_slots` int(255) NOT NULL,
	`credits` text NOT NULL,
	`l_slot1` text DEFAULT NULL,
	`l_slot2` text DEFAULT NULL,
	`l_slot3` text DEFAULT NULL,
	`l_slot4` text DEFAULT NULL,
	`l_slot5` text DEFAULT NULL,
	`l_slot6` text DEFAULT NULL,
	`l_slot7` text DEFAULT NULL,
	`l_slot8` text DEFAULT NULL,
	`l_slot9` text DEFAULT NULL,
	`l_slot10` text DEFAULT NULL,
	`inventory` mediumtext NOT NULL,
	PRIMARY KEY (`steamid`)
);

CREATE TABLE IF NOT EXISTS `moat_inventories_test` (
	`steamid` varchar(100) NOT NULL,
	`max_slots` int(255) NOT NULL,
	`credits` mediumtext NOT NULL,
	`l_slot1` mediumtext DEFAULT NULL,
	`l_slot2` mediumtext DEFAULT NULL,
	`l_slot3` mediumtext DEFAULT NULL,
	`l_slot4` mediumtext DEFAULT NULL,
	`l_slot5` mediumtext DEFAULT NULL,
	`l_slot6` mediumtext DEFAULT NULL,
	`l_slot7` mediumtext DEFAULT NULL,
	`l_slot8` mediumtext DEFAULT NULL,
	`l_slot9` mediumtext DEFAULT NULL,
	`l_slot10` mediumtext DEFAULT NULL,
	`inventory` longtext NOT NULL,
	PRIMARY KEY (`steamid`)
);

CREATE TABLE IF NOT EXISTS `moat_itemqueue` (
	`id` int(255) NOT NULL AUTO_INCREMENT,
	`steamid` varchar(255) NOT NULL,
	`item` mediumtext NOT NULL,
	PRIMARY KEY (`id`)
);

CREATE TABLE IF NOT EXISTS `moat_jpgames` (
	`ID` int(11) NOT NULL AUTO_INCREMENT,
	`time_end` int(11) NOT NULL,
	`active` int(11) NOT NULL,
	`cool` int(11) DEFAULT NULL,
	PRIMARY KEY (`ID`)
);

CREATE TABLE IF NOT EXISTS `moat_jpplayers` (
	`steamid` varchar(255) NOT NULL,
	`money` text NOT NULL,
	`winner` int(11) DEFAULT NULL,
	PRIMARY KEY (`steamid`)
);

CREATE TABLE IF NOT EXISTS `moat_jpservers` (
	`ID` int(11) NOT NULL AUTO_INCREMENT,
	`crc` mediumtext NOT NULL,
	PRIMARY KEY (`ID`)
);

CREATE TABLE IF NOT EXISTS `moat_jpwinners` (
	`steamid` varchar(32) NOT NULL,
	`money` mediumtext NOT NULL,
	PRIMARY KEY (`steamid`)
);

CREATE TABLE IF NOT EXISTS `moat_lastnum` (
	`num` int(11) NOT NULL,
	PRIMARY KEY (`num`)
);

CREATE TABLE IF NOT EXISTS `moat_levels` (
	`steam_id` bigint(20) NOT NULL,
	`color_r` int(11) DEFAULT NULL,
	`color_g` int(11) DEFAULT NULL,
	`color_b` int(11) DEFAULT NULL,
	`color_effect` int(11) DEFAULT NULL,
	`updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
	PRIMARY KEY (`steam_id`)
);

CREATE TABLE IF NOT EXISTS `moat_logs` (
	`ID` int(11) NOT NULL AUTO_INCREMENT,
	`time` int(11) NOT NULL,
	`message` mediumtext NOT NULL,
	PRIMARY KEY (`ID`)
);

CREATE TABLE IF NOT EXISTS `moat_lottery` (
	`amount` int(11) NOT NULL,
	PRIMARY KEY (`amount`)
);

CREATE TABLE IF NOT EXISTS `moat_lottery_last` (
	`num` int(11) NOT NULL,
	PRIMARY KEY (`num`)
);

CREATE TABLE IF NOT EXISTS `moat_lottery_players` (
	`steamid` varchar(32) NOT NULL,
	`name` varchar(255) DEFAULT NULL,
	`ticket` int(11) NOT NULL,
	PRIMARY KEY (`steamid`)
);

CREATE TABLE IF NOT EXISTS `moat_lottery_winners` (
	`steamid` varchar(32) NOT NULL,
	`amount` int(11) NOT NULL,
	PRIMARY KEY (`steamid`)
);

CREATE TABLE IF NOT EXISTS `moat_mapvote_prevent` (
	`active` tinyint(4) NOT NULL,
	PRIMARY KEY (`active`)
);

CREATE TABLE IF NOT EXISTS `moat_megavape` (
	`itemid` varchar(100) NOT NULL,
	`time` int(11) NOT NULL,
	PRIMARY KEY (`itemid`)
);

CREATE TABLE IF NOT EXISTS `moat_namerewards` (
	`steamid` varchar(32) NOT NULL,
	`last_name` int(11) NOT NULL,
	`last_reward` int(11) NOT NULL,
	`pending_ic` int(11) NOT NULL,
	`pending_sc` int(11) NOT NULL,
	PRIMARY KEY (`steamid`)
);

CREATE TABLE IF NOT EXISTS `moat_pendingitems` (
	`steamid` varchar(32) NOT NULL,
	`item` mediumtext NOT NULL
);

CREATE TABLE IF NOT EXISTS `moat_rollsave` (
	`id` int(255) NOT NULL AUTO_INCREMENT,
	`steamid` varchar(32) NOT NULL,
	`item_tbl` mediumtext NOT NULL,
	PRIMARY KEY (`id`),
	KEY `steamid` (`steamid`)
);

CREATE TABLE IF NOT EXISTS `moat_staff_commands` (
	`id` int(10) unsigned NOT NULL AUTO_INCREMENT,
	`staff_steamid` varchar(30) NOT NULL,
	`staff_rank` text NOT NULL,
	`staff_name` mediumtext NOT NULL,
	`command` mediumtext NOT NULL,
	`steamid` varchar(30) DEFAULT NULL,
	`args` mediumtext DEFAULT NULL,
	`server_for` mediumtext DEFAULT NULL,
	`server_ran` mediumtext NOT NULL,
	`date` timestamp DEFAULT CURRENT_TIMESTAMP,
	PRIMARY KEY (`id`)
);

CREATE TABLE IF NOT EXISTS `moat_stats` (
	`steamid` varchar(32) NOT NULL,
	`stats_tbl` mediumtext NOT NULL,
	PRIMARY KEY (`steamid`)
);

CREATE TABLE IF NOT EXISTS `moat_tradebans` (
	`steamid64` bigint(20) unsigned NOT NULL,
	`banner` bigint(20) unsigned DEFAULT NULL,
	`reason` varchar(128) NOT NULL,
	`unban_time` timestamp NULL DEFAULT NULL,
	KEY `steamid64` (`steamid64`) USING BTREE
);

CREATE TABLE IF NOT EXISTS `moat_trades` (
	`ID` int(11) NOT NULL AUTO_INCREMENT,
	`time` int(11) NOT NULL,
	`my_steamid` varchar(30) NOT NULL,
	`their_steamid` varchar(30) NOT NULL,
	`my_nick` mediumtext NOT NULL,
	`their_nick` mediumtext NOT NULL,
	`trade_tbl` mediumtext NOT NULL,
	PRIMARY KEY (`ID`)
);

CREATE TABLE IF NOT EXISTS `moat_versus` (
	`steamid` varchar(20) NOT NULL,
	`money` int(11) NOT NULL,
	`time` int(11) DEFAULT NULL,
	`other` varchar(20) DEFAULT NULL,
	`winner` varchar(20) DEFAULT NULL,
	`rewarded` tinyint(1) DEFAULT NULL,
	PRIMARY KEY (`steamid`)
);

CREATE TABLE IF NOT EXISTS `moat_versus_dev` (
	`steamid` varchar(100) NOT NULL,
	`money` int(11) NOT NULL,
	`time` int(11) DEFAULT NULL,
	`other` varchar(255) DEFAULT NULL,
	`winner` varchar(255) DEFAULT NULL,
	`rewarded` tinyint(1) DEFAULT NULL,
	PRIMARY KEY (`steamid`)
);

CREATE TABLE IF NOT EXISTS `moat_versus_meme` (
	`steamid` varchar(100) NOT NULL,
	`money` int(11) NOT NULL,
	`time` int(11) DEFAULT NULL,
	`other` varchar(255) DEFAULT NULL,
	`winner` varchar(255) DEFAULT NULL,
	`rewarded` tinyint(1) DEFAULT NULL,
	PRIMARY KEY (`steamid`)
);

CREATE TABLE IF NOT EXISTS `moat_versus_test` (
	`steamid` varchar(20) NOT NULL,
	`money` int(11) NOT NULL,
	`time` int(11) DEFAULT NULL,
	`other` varchar(20) DEFAULT NULL,
	`winner` varchar(20) DEFAULT NULL,
	PRIMARY KEY (`steamid`)
);

CREATE TABLE IF NOT EXISTS `moat_versus_v2` (
	`id` int(10) unsigned NOT NULL AUTO_INCREMENT,
	`creator_steamid64` bigint(20) unsigned NOT NULL,
	`money` int(10) unsigned NOT NULL,
	`taker_steamid64` bigint(20) unsigned DEFAULT NULL,
	`roll_time` timestamp NULL DEFAULT NULL,
	`creator_won` tinyint(1) DEFAULT NULL,
	`reward_time` timestamp NULL DEFAULT NULL,
	`cancel_time` timestamp NULL DEFAULT NULL,
	`creation_time` timestamp DEFAULT CURRENT_TIMESTAMP,
	PRIMARY KEY (`id`),
	KEY `id` (`id`,`reward_time`)
);

CREATE TABLE IF NOT EXISTS `moat_versuslogs` (
	`ID` int(11) NOT NULL AUTO_INCREMENT,
	`steamid` varchar(255) NOT NULL,
	`other` varchar(255) NOT NULL,
	`winner` varchar(255) NOT NULL,
	`amount` int(11) NOT NULL,
	`time` int(11) NOT NULL,
	`tax` int(11) DEFAULT NULL,
	PRIMARY KEY (`ID`)
);

CREATE TABLE IF NOT EXISTS `moat_versusstreaks` (
	`steamid` varchar(100) NOT NULL,
	`streak` int(11) NOT NULL,
	PRIMARY KEY (`steamid`)
);

CREATE TABLE IF NOT EXISTS `moat_versusstreaks_history` (
	`ID` int(11) NOT NULL AUTO_INCREMENT,
	`steamid` varchar(255) NOT NULL,
	`streak` int(11) NOT NULL,
	`time` int(11) NOT NULL,
	PRIMARY KEY (`ID`)
);

CREATE TABLE IF NOT EXISTS `moat_veterangamers` (
	`steamid` varchar(20) NOT NULL,
	PRIMARY KEY (`steamid`)
);

CREATE TABLE IF NOT EXISTS `moat_vswinners` (
	`ID` int(11) NOT NULL AUTO_INCREMENT,
	`steamid` varchar(255) NOT NULL,
	`money` int(11) NOT NULL,
	PRIMARY KEY (`ID`)
);

CREATE TABLE IF NOT EXISTS `mse_logs` (
	`id` int(11) NOT NULL AUTO_INCREMENT,
	`steamid` varchar(30) NOT NULL,
	`cmd` mediumtext NOT NULL,
	`time` mediumtext NOT NULL,
	PRIMARY KEY (`id`)
);

CREATE TABLE IF NOT EXISTS `mse_players` (
	`id` int(11) NOT NULL AUTO_INCREMENT,
	`steamid` varchar(30) NOT NULL,
	`rank` mediumtext NOT NULL,
	`cooldown` int(11) NOT NULL,
	`amount` int(11) NOT NULL,
	PRIMARY KEY (`id`)
);

CREATE TABLE IF NOT EXISTS `player` (
	`steam_id` bigint(17) NOT NULL,
	`name` varchar(100) DEFAULT NULL,
	`rank` varchar(60) DEFAULT NULL,
	`first_join` int(10) DEFAULT NULL,
	`last_join` int(10) DEFAULT NULL,
	`avatar_url` varchar(150) DEFAULT NULL,
	`playtime` int(10) DEFAULT NULL,
	`inventory_credits` int(10) unsigned DEFAULT NULL,
	`event_credits` int(10) unsigned DEFAULT NULL,
	`donator_credits` int(10) unsigned DEFAULT NULL,
	`extra` varchar(150) DEFAULT NULL,
	`rank_expire` int(11) DEFAULT NULL,
	`rank_expire_to` varchar(32) DEFAULT NULL,
	`rank_changed` int(11) DEFAULT NULL,
	`mvp_access` int(11) DEFAULT NULL,
	PRIMARY KEY (`steam_id`),
	KEY `rank` (`rank`),
	KEY `inventory_credits` (`inventory_credits`),
	KEY `playtime` (`playtime`),
	KEY `last_join` (`last_join`),
	FULLTEXT KEY `name` (`name`)
);

CREATE TABLE IF NOT EXISTS `player_bans` (
	`id` int(5) NOT NULL AUTO_INCREMENT,
	`time` int(11) DEFAULT NULL,
	`steam_id` bigint(17) DEFAULT NULL,
	`staff_steam_id` bigint(17) DEFAULT NULL,
	`name` varchar(100) DEFAULT NULL,
	`staff_name` varchar(100) DEFAULT NULL,
	`length` int(11) DEFAULT NULL,
	`reason` varchar(200) DEFAULT NULL,
	`unban_reason` varchar(200) DEFAULT NULL,
	PRIMARY KEY (`id`),
	KEY `SteamID` (`steam_id`),
	KEY `A_SteamID` (`staff_steam_id`),
	KEY `Name` (`name`),
	KEY `A_Name` (`staff_name`),
	KEY `length` (`length`),
	KEY `time` (`time`)
);

CREATE TABLE IF NOT EXISTS `player_bans_comms` (
	`id` int(10) unsigned NOT NULL AUTO_INCREMENT,
	`ban_type` tinyint(3) unsigned NOT NULL,
	`steam_id` bigint(20) unsigned NOT NULL,
	`staff_steam_id` bigint(20) unsigned NOT NULL,
	`name` varchar(32) DEFAULT NULL,
	`staff_name` varchar(32) DEFAULT NULL,
	`length` int(10) unsigned DEFAULT NULL,
	`time` int(10) unsigned DEFAULT NULL,
	`reason` varchar(255) DEFAULT NULL,
	`unban_reason` varchar(255) DEFAULT NULL,
	`date` timestamp DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
	PRIMARY KEY (`id`),
	KEY `steam_id` (`steam_id`),
	KEY `length` (`length`),
	KEY `time` (`time`),
	KEY `unban_reason` (`unban_reason`)
);

CREATE TABLE IF NOT EXISTS `player_bans_trading` (
	`steam_id` bigint(20) NOT NULL,
	`staff_steam_id` bigint(20) NOT NULL,
	`reason` varchar(255) NOT NULL,
	`date` timestamp DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
	PRIMARY KEY (`steam_id`)
);

CREATE TABLE IF NOT EXISTS `player_bans_votekick` (
	`steam_id` bigint(20) NOT NULL,
	`staff_steam_id` bigint(20) NOT NULL,
	`reason` varchar(255) NOT NULL,
	`date` timestamp DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
	PRIMARY KEY (`steam_id`)
);

CREATE TABLE IF NOT EXISTS `player_cmds` (
	`name` varchar(100) NOT NULL,
	`flag` char(1) DEFAULT NULL,
	`weight` bit(1) DEFAULT b'0',
	`args` mediumtext DEFAULT NULL,
	PRIMARY KEY (`name`)
);

CREATE TABLE IF NOT EXISTS `player_gmod` (
	`data_day` timestamp DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
	`owners` int(11) NOT NULL,
	`price` float NOT NULL,
	`event` varchar(255) DEFAULT NULL,
	`event_link` varchar(255) DEFAULT NULL,
	PRIMARY KEY (`data_day`)
);

CREATE TABLE IF NOT EXISTS `player_iplog` (
	`LastSeen` bigint(20) NOT NULL,
	`SteamID` varchar(50) NOT NULL,
	`Address` varchar(50) NOT NULL,
	KEY `SteamID` (`SteamID`),
	KEY `Address` (`Address`)
);

CREATE TABLE IF NOT EXISTS `player_logs` (
	`id` int(10) unsigned NOT NULL AUTO_INCREMENT,
	`steam_id` bigint(20) unsigned NOT NULL,
	`name` varchar(100) NOT NULL,
	`cmd` varchar(100) NOT NULL,
	`args` text NOT NULL,
	`date` timestamp DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
	PRIMARY KEY (`id`)
);

CREATE TABLE IF NOT EXISTS `player_ranks` (
	`name` varchar(255) NOT NULL,
	`weight` int(11) NOT NULL,
	`flags` tinytext NOT NULL,
	PRIMARY KEY (`name`)
);

CREATE TABLE IF NOT EXISTS `player_servers` (
	`id` int(10) unsigned NOT NULL AUTO_INCREMENT,
	`name` varchar(255) NOT NULL,
	`full_ip` varchar(45) DEFAULT NULL,
	`map` varchar(255) DEFAULT 'NULL',
	`players` int(10) unsigned DEFAULT NULL,
	`staff` int(10) unsigned DEFAULT NULL,
	`ip` varchar(255) NOT NULL,
	`port` varchar(10) NOT NULL,
	`custom_ip` varchar(255) NOT NULL,
	`join_url` varchar(255) DEFAULT NULL,
	`hostname` varchar(255) DEFAULT 'NULL',
	`map_changed` int(10) unsigned DEFAULT NULL,
	`max_players` int(10) unsigned DEFAULT NULL,
	`rounds_left` int(10) unsigned DEFAULT NULL,
	`round_state` varchar(50) NOT NULL,
	`time_left` int(10) unsigned DEFAULT NULL,
	`map_time_left` int(10) unsigned DEFAULT NULL,
	`traitors_alive` int(10) unsigned DEFAULT NULL,
	`innocents_alive` int(10) unsigned DEFAULT NULL,
	`others_alive` int(10) unsigned DEFAULT NULL,
	`spectators` int(10) unsigned DEFAULT NULL,
	`traitor_wins` int(10) unsigned DEFAULT NULL,
	`innocent_wins` int(10) unsigned DEFAULT NULL,
	`top_player_steamid` bigint(20) unsigned DEFAULT NULL,
	`top_player_name` varchar(255) DEFAULT NULL,
	`top_player_score` int(10) unsigned DEFAULT NULL,
	`special_round` varchar(255) DEFAULT NULL,
	`map_event` varchar(255) DEFAULT NULL,
	`last_update` timestamp DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
	PRIMARY KEY (`id`),
	UNIQUE KEY `ip` (`ip`,`port`),
	UNIQUE KEY `full_ip` (`full_ip`)
);

CREATE TABLE IF NOT EXISTS `player_sessions` (
	`steamid64` bigint(20) NOT NULL,
	`time` int(11) NOT NULL,
	`server` varchar(32) NOT NULL,
	`name` varchar(100) NOT NULL,
	`rank` mediumtext NOT NULL,
	`level` int(11) NOT NULL,
	`team_kills` int(11) NOT NULL,
	`slays` int(11) NOT NULL,
	PRIMARY KEY (`steamid64`),
	KEY `name` (`name`)
);

CREATE TABLE IF NOT EXISTS `player_warns` (
	`id` int(10) unsigned NOT NULL AUTO_INCREMENT,
	`steam_id` bigint(20) unsigned NOT NULL,
	`staff_steam_id` bigint(20) unsigned NOT NULL,
	`name` varchar(100) NOT NULL,
	`staff_name` varchar(100) NOT NULL,
	`time` int(10) unsigned NOT NULL,
	`reason` varchar(255) NOT NULL,
	`acknowledged` int(10) unsigned DEFAULT NULL,
	PRIMARY KEY (`id`),
	KEY `acknowledged` (`acknowledged`),
	KEY `steam_id` (`steam_id`)
);

CREATE TABLE IF NOT EXISTS `rcon_commands` (
	`id` int(10) unsigned NOT NULL AUTO_INCREMENT,
	`staff_steamid` varchar(30) NOT NULL,
	`staff_rank` text NOT NULL,
	`staff_name` text DEFAULT NULL,
	`server` varchar(255) NOT NULL,
	`command` mediumtext NOT NULL,
	`args` text DEFAULT NULL,
	`steamid` varchar(30) DEFAULT NULL,
	`date` timestamp DEFAULT CURRENT_TIMESTAMP,
	PRIMARY KEY (`id`)
);

CREATE TABLE IF NOT EXISTS `rcon_errors` (
	`id` int(11) NOT NULL AUTO_INCREMENT,
	`error` mediumtext NOT NULL,
	`serverip` varchar(255) NOT NULL,
	`realm` tinyint(1) NOT NULL,
	`stack` mediumtext DEFAULT NULL,
	`steamid` varchar(20) DEFAULT NULL,
	`date` timestamp DEFAULT CURRENT_TIMESTAMP,
	PRIMARY KEY (`id`)
);

CREATE TABLE IF NOT EXISTS `rcon_queue` (
	`cmdid` int(10) unsigned NOT NULL,
	`server` varchar(255) NOT NULL,
	`date` timestamp DEFAULT CURRENT_TIMESTAMP,
	PRIMARY KEY (`cmdid`,`server`),
	CONSTRAINT `fk_rcon_queue_rcon_commands` FOREIGN KEY (`cmdid`) REFERENCES `rcon_commands` (`id`) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS `staff_tracker` (
	`id` int(10) unsigned NOT NULL AUTO_INCREMENT,
	`steamid` bigint(20) unsigned NOT NULL,
	`join_time` timestamp DEFAULT CURRENT_TIMESTAMP,
	`leave_time` timestamp DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
	`rounds_played` tinyint(10) unsigned NOT NULL DEFAULT 0,
	`rounds_on` int(10) unsigned NOT NULL DEFAULT 0,
	`time_played` int(10) unsigned NOT NULL DEFAULT 0,
	`reports_handled` smallint(10) unsigned NOT NULL DEFAULT 0,
	`server_ip` int(4) unsigned NOT NULL,
	`server_port` smallint(2) unsigned NOT NULL,
	PRIMARY KEY (`id`),
	KEY `join_time` (`join_time`),
	KEY `leave_time` (`leave_time`),
	KEY `steamid` (`steamid`),
	KEY `server_ip` (`server_ip`),
	KEY `server_port` (`server_port`)
);

CREATE TABLE IF NOT EXISTS `stats` (
	`id` int(11) NOT NULL AUTO_INCREMENT,
	`steamid` varchar(30) NOT NULL,
	`credits` int(11) NOT NULL,
	`time` int(11) NOT NULL,
	`rank` mediumtext NOT NULL,
	`name` mediumtext NOT NULL,
	PRIMARY KEY (`id`)
);

CREATE TABLE IF NOT EXISTS `steam_rewards` (
	`steam` char(20) NOT NULL,
	`value` int(11) NOT NULL,
	PRIMARY KEY (`steam`)
);

CREATE TABLE IF NOT EXISTS `titles` (
	`id` int(11) NOT NULL AUTO_INCREMENT,
	`steamid` varchar(30) NOT NULL,
	`title` mediumtext NOT NULL,
	`color` mediumtext NOT NULL,
	`changerid` varchar(30) NOT NULL,
	PRIMARY KEY (`id`),
	UNIQUE KEY `steamid` (`steamid`)
);

CREATE TABLE IF NOT EXISTS `customnotifications_notifications` (
	`id` bigint(20) unsigned NOT NULL AUTO_INCREMENT COMMENT 'ID Number',
	`options` mediumtext DEFAULT NULL,
	`enabled` tinyint(1) NOT NULL DEFAULT 1,
	`to_run` int(10) DEFAULT 0,
	`bf_options` int(11) NOT NULL DEFAULT 0,
	`url` mediumtext DEFAULT NULL,
	`member_id` int(11) NOT NULL DEFAULT 0,
	`sent_on` int(11) DEFAULT NULL,
	PRIMARY KEY (`id`)
);

CREATE TABLE IF NOT EXISTS `damagelog_oldlogs` (
	`id` int(10) unsigned NOT NULL AUTO_INCREMENT,
	`date` timestamp DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
	`server` tinytext NOT NULL,
	`map` tinytext NOT NULL,
	`round` tinyint(4) NOT NULL,
	`damagelog` longblob NOT NULL,
	PRIMARY KEY (`id`)
);

CREATE TABLE IF NOT EXISTS `damagelog_weapons` (
	`class` varchar(100) NOT NULL,
	`name` varchar(255) NOT NULL,
	PRIMARY KEY (`class`)
);

CREATE TABLE IF NOT EXISTS `core_ttt_oct` (
	`steamid` varchar(100) NOT NULL,
	`max_slots` int(255) NOT NULL,
	`credits` mediumtext NOT NULL,
	`l_slot1` mediumtext DEFAULT NULL,
	`l_slot2` mediumtext DEFAULT NULL,
	`l_slot3` mediumtext DEFAULT NULL,
	`l_slot4` mediumtext DEFAULT NULL,
	`l_slot5` mediumtext DEFAULT NULL,
	`l_slot6` mediumtext DEFAULT NULL,
	`l_slot7` mediumtext DEFAULT NULL,
	`l_slot8` mediumtext DEFAULT NULL,
	`l_slot9` mediumtext DEFAULT NULL,
	`l_slot10` mediumtext DEFAULT NULL,
	`inventory` longtext NOT NULL,
	PRIMARY KEY (`steamid`)
);

CREATE TABLE IF NOT EXISTS `core_ttt_old` (
	`steamid` varchar(100) NOT NULL,
	`max_slots` int(255) NOT NULL,
	`credits` mediumtext NOT NULL,
	`l_slot1` mediumtext DEFAULT NULL,
	`l_slot2` mediumtext DEFAULT NULL,
	`l_slot3` mediumtext DEFAULT NULL,
	`l_slot4` mediumtext DEFAULT NULL,
	`l_slot5` mediumtext DEFAULT NULL,
	`l_slot6` mediumtext DEFAULT NULL,
	`l_slot7` mediumtext DEFAULT NULL,
	`l_slot8` mediumtext DEFAULT NULL,
	`l_slot9` mediumtext DEFAULT NULL,
	`l_slot10` mediumtext DEFAULT NULL,
	`inventory` longtext NOT NULL,
	PRIMARY KEY (`steamid`)
);
