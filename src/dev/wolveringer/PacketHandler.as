package dev.wolveringer
{
    import flash.utils.describeType;
    import flash.utils.setTimeout;
    import flash.utils.getQualifiedClassName;
    import flash.utils.getTimer;
    import jp.assasans.protanki.client.chainloader.Main;

    // import flash.filesystem.FileMode;
    // import flash.filesystem.File;
    // import flash.filesystem.FileStream;

    public class PacketHandler
    {
        private static var logFile/* : FileStream */;
        private static function shouldPrintPacket(direction:String, packet:Object):Boolean
        {
            return true;
            if (packet.method_1839() == 45 || packet.method_1839() == 46)
            {
                /* ping/pong */
                return false;
            }

            return true;
            // switch(packet.method_1839()) {
            // case 34:
            // return true;

            // default:
            // return true;
            // }

            if ("moveCommand" in packet || "rotateTurretCommand" in packet)
            {
                return false;
            }

            //return packet.method_1839() == 54;
            return false;

            switch (packet.getPacketId())
            {
                /* Model 0: account login */
                /* Model 1: account login hash */
                case 932564569: /* S2C update */
                case 655372891: /* S2C login failed */
                case -845588810: /* C2S login */
                    return false;

                    /* Model 2: account login social media */
                case -1317889894: /* ??? (Unused) */
                    return true;

                    /* Model 3: account login external */

                    /* Model 4: resource loader */
                case -1797047325: /* S2C load dependencies */
                case -82304134: /* C2S dependencies loaded */
                    return false;
                case -1282173466: /* S2C resources loaded */
                case 2001736388: /* S2C initialize encryption */
                case -1864333717: /* C2S encryption initialized */
                    return true;
                case -1807685988: /* ??? not in use */
                    return true;

                    /* Model 5: invites (not supported by protanki) */

                    /* Model 6: captcha */
                case 321971701: /* S2C parameters */
                case -1670408519: /* S2C show */
                case -349828108: /* C2S request location */
                case 1271163230: /* C2S validate captcha */
                case -819536476: /* S2C captcha validated */
                case -373510957: /* S2C captcha failed */
                    return false;

                    /* Model 7: ban */
                case 1200280053: /* S2C temporary */
                case -600078553: /* S2C permanent */
                    return true;

                    /* Model 8: account register */
                case 1083705823: /* C2S validate uid */
                case 442888643: /* S2C uid busy */
                case -706679202: /* S2C uid free */
                case 1480924803: /* S2C uid incorrect */
                case -1277343167: /* S2C parameters */
                case 427083290: /* C2S submit */
                case 1003297349: /* S2C captcha required */
                    return false;
                case -653665247:
                    return true;

                    /* Model 9: account recover */

                    /* Model 10: ?? (TODO!) */
                    /* Model 11: account premium */

                    /* Model 12: lobby layout switch (triggered by model 17) */
                case 1118835050: /* S2C start */
                case -593368100: /* S2C end */
                    return false;

                    /* Model 13: friends */

                    /* Model 14: link */
                case -604091695: /* C2S activate link */
                case 1152930968: /* C2S result alive */
                case 1132011721: /* C2S result dead */
                case -983139626: /* C2S query */
                    return false;

                    /* Model 15: ??? (TODO!) */
                    /* Model 16: ??? (TODO!) */

                    /* Model 17: layout switch */
                case 1452181070: /* C2S server select */
                case 1153801756: /* C2S payment */
                case -479046431: /* C2S garage */
                case 377959142: /* C2S exit battle */
                    return false;

                    /* Model 18: user notify */
                case -1895446889: /* S2C notify user in battle */
                case -962759489: /* S2C notify update user rank */
                case 1941694508: /* S2C notify user battle leave */
                case 2041598093: /* S2C update user online status */
                case -2069508071: /* S2C premium time left */
                case 1774907609: /* C2S subscribe user */
                case -2040152224: /* C2S unsubscribe users */
                    return false;
                case -1353047954: /* S2C Set user id (I don't yet know when this will be send) */
                    return true;

                    /* Model 19: quests */
                    /* Model 20: quest reward */
                    /* Model 21: ??? (TODO!) */
                    /* Model 22: ??? (Something related to social networks, imo not used) */
                    /* Model 23: ??? (TODO!) */
                    /* Model 24: account settings (email and password) */
                    /* Model 25: alert */
                case -322235316: /* S2C show */
                    return true;

                    /* Model 26: alert server halt */
                case -1712113407: /* S2C scheduled */
                    return true;

                    /* Model 27: ?? (TODO!) */

                    /* Model 28: global chat*/
                case 178154988: /* S2C chat init parameters */
                case 744948472: /* S2C chat antiflood parameters */
                case 1993050216: /* S2C clean user message */
                case -1263520410: /* S2C show messages */
                    return false;
                case -920985123:
                case -1062190024:
                case 705454610:
                    return true;

                    /* Model 29: account rank */

                    /* Model 30: battle create */
                case -838186985: /* S2C parameters */
                    return false;
                case 566338297:
                case 947161947:
                case 120401338:
                case -614313838:
                case 566652736:
                case -2135234426:
                case -1491503394:
                    return true;

                    /* Model 31: battle list */
                case -324155151: /* S2C list destroy */
                case 552006706: /* S2C list create */
                case 802300608: /* S2C battle create */
                case -1848001147: /* S2C battle remove */
                case 2092412133: /* S2C battle select | C2S battle select */
                    return false;

                    /* Model 32: battle user list */
                case -169305322: /* S2C user join battle */
                case 1447204641: /* S2C user join battle with team */
                    return false;
                case 1149131596:
                case -2133657895:
                case 2011860838:
                case -994817471:
                case -751613832:
                case 504016996:
                    return false;

                    /* Model 33: battle info (info for the currently active battle) */
                case -911626491: /* S2C add user*/
                case 1924874982: /* S2C remove User */
                case 118447426: /* S2C add user to team */
                case -879771375: /* S2C battle stop */
                case 546722394: /* S2C round finish */
                case -344514517: /* S2C round start */
                case -1702097572: /* S2C swap teams */
                case 1561014187: /* S2C update name */
                case 1428217189: /* S2C update team score */
                case -375282889: /* S2C update user score */
                case -1263036614: /* S2C update user kills */
                case -698399183: /* S2C update suspicious state */
                case -602527073: /* S2C info destroy */
                    return false;
                case 1229594925:
                case -10847382:
                case -1315002220:
                case 1534651002:
                case -831998018:
                case -1284211503:
                    return true;

                    /* Model 34: garage */
                case -255516505: /* S2C init depot (bought items) */
                case -300370823: /* S2C init market (buyable items) */
                case 2062201643: /* S2C init mounted */
                case 1318061480: /* S2C show category */
                case -1638767166: /* S2C show alert (accepted by sending a new presents accept packet) */
                case -1763914667: /* S2C select first item */
                case -803365239: /* S2C select item | C2S select item */
                case -1154479430: /* C2S presents accept */
                case -1518850075: /* C2S presents confirm purchase */
                case -2001666558: /* S2C presents remove */
                case -1961983005: /* C2S buy item */
                case -1505530736: /* C2S mount item */
                case -523392052: /* C2S buy kit */
                case -161726525: /* C2S rename */
                case -471022967: /* S2C rename failed */
                case -1968445033: /* S2C rename success */
                    return false;
                case 1211186637: /* S2C ??? */
                case 1091756732: /* S2C fit (i have no clue what this means but can be triggered with a is a big grey button; cant be used when in battle) */
                    return true;

                    /* Model 35: uid check */
                case -635715470: /* C2S request */
                case -1565553333: /* C2S response */
                    return true;

                    /* Model 36: battle bonus (TODO!) */
                case 1831462385: /* S2C spawn bonus */
                    return false;

                    /* Model 37: ?? (TODO, battle fund etc) */
                    /* Model 38: ??? (not used) */

                    /* Model 39: tank */
                case -114968993: /* C2S turret command */
                case 329279865: /* C2S move command */
                case -1683279062: /* C2S move turret command */
                case -1749108178: /* C2S move control flags */
                case -64696933: /* S2C move command */
                case 1927704181: /* S2C turret command */
                case 1516578027: /* S2C move turret command */
                case -611961116: /* S2C health */
                case 875259457: /* S2C spawn */
                case 581377054: /* S2C update temperature */
                    return false;
                case -42520728: /* S2C kill */
                case 1868573511: /* S2C dead */
                case -1378839846: /* C2S ready 2 place */
                case 1178028365: /* C2S ready 2 activate */
                case -1639713644: /* S2C effect apply */
                case -1994318624: /* S2C effect remove */
                case -301298508: /* S2C move control flags */
                case -157204477: /* S2C update orientation */
                case -1672577397: /* S2C update speed */
                case 1719707347: /* S2C destroy */
                case 268832557: /* C2S ??? */
                    return true;

                    /* Model 40: ??? (TODO!) */

                    /* Model 41: battle bonus (Note: Mondel 36 is pretty similar!) */
                    /* Model 42: battle ctf */
                    /* Model 43: battle drugs */
                    /* Model 44: battle users */

                    /* Model 45: ping measure */
                case -555602629: /* S2C ping */
                case 1484572481: /* C2S pong */
                    return false;

                    /* Model 46: server session */
                case 34068208: /* S2C sync */
                case 2074243318: /* C2S sync response */
                    return false;

                    /* Model 47: battle damage */
                case -1165230470: /* S2C indicator */
                    return false;

                    /* Model 48: battle user stats */

                    /* Model 49: weapon ??? */
                    /* Model 50: weapon ??? */
                    /* Model 51: weapon twins */
                    /* Model 52: weapon ??? */
                    /* Model 53: weapon ??? */
                    /* Model 54: weapon railgun */
                    /* Model 55: weapon ??? */
                    /* Model 56: weapon ??? */
                    /* Model 57: weapon ??? */

                    /* Model 58: ??? */

                    /* Model 59: ??? (suicide) */
                    /* Model 60: battle cp */
                    /* Model 61: battle message */
                    /* Model 62: battle mines */

                    /* Model 63: ?? */
                    /* Model 64: ?? */
                    /* Model 65: ?? (sounds?) */
                    /* Model 66: ?? */

                    /* Model 67: achtivements */
                    /* Model 68: news */

                    /* Model 69: payment */
                case 1566424318: /* S2C completed */
                    return true;

                    /* Model 70: weapon ?? */
                    /* Model 71: battle ctf (again?) */

                    /* Model 72: weapon ?? */
                case 29211250:
                    return true;

                    /* Model 73: beginner pass */
                case 29211250: /* S2C activate */
                    return true;
                default:
                    return true;
            }
        }

        private static function dumpPacket(direction:String, name:String, packet:*):void
        {
            const xml:XML = new XML(describeType(packet));
            if(logFile) {
                // logFile.writeUTFBytes(direction + " Packet " + name +" " + packet + " Module: " + packet.method_1839() + "\n");
            }
            trace(direction + " Packet " + name, packet, "Module:", 0 /* packet.method_1839() */);
            for each (var variable:XML in xml.variable)
            {
                const varName:String = variable.attribute("name");
                var value:* = packet[varName];
                if(logFile) {
                    logFile.writeUTFBytes(" " + varName + " (" + variable.attribute("type") + "): " + value + "\n");
                }
                
                if (typeof value == "string" && value.length > 1000)
                {
                    value = value.substring(0, 100) + " [...]";
                }

                if(value is Vector.<int> && value.length > 32) {
                    value = "[[ Vector<int> of length " + value.length + " ]]";
                }
                trace(" " + varName + " (" + variable.attribute("type") + "): " + value);
            }
        }

        public static function packetIncoming(packet:Object):*
        {
            if (shouldPrintPacket("IN", packet))
            {
                dumpPacket("IN", getQualifiedClassName(packet), packet);
            }

            if("suspicious" in packet && packet.suspicious) {
                dumpPacket("SUS", getQualifiedClassName(packet), packet);
                return;
            }
            
            return;
            switch (packet.getPacketId())
            {
                case -42520728:
                    trace("Send respawn!");
                    const CPacketReady2Place:* = Utils.getTanksDefinition('package_266.class_1084') as Class;
                    sendPacket(new CPacketReady2Place());
                    return;

                case -152638117: /* map info */

                    BattleManager.instance.mapInitData = JSON.parse(packet.json);
                    trace("Received map info: " + packet.json);
                    setTimeout(function():void
                    {
                        if(Main.instance.loaderInfo.parameters["disable-3d-rendering"] == "yes") {
                            RenderToggle.instance.Disable();
                        }
                        
                        /* Send battle info a little later as we must wait for the map resource to load. */
                        BattleManager.instance.sendBattleInfo();
                    }, 1000);
                    return;

                case 2092412133: /* battle select: select battle */
                    BattleManager.instance.handleServerBattleSelected(packet.item);
                    break;

                case -1282173466: /* S2CResourceLoaderResourcesLoaded */
                    const loginInfo: Array = Main.instance.loaderInfo.parameters["auto-login"].split(":");
                    if(loginInfo[0] && loginInfo[1]) {
                        trace("Auto login with password for " + loginInfo[0]);
                        const CPacketAccountLoginPassword: * = Utils.getTanksDefinition("package_262.class_829");
                        sendPacket(new CPacketAccountLoginPassword(loginInfo[0], loginInfo[1], false));
                    }
                    break;

                default:
                    break;
            }
        }

        public static function packetOutgoing(packet:Object):void
        {
            if (shouldPrintPacket("OUT", packet))
            {
                dumpPacket("OUT", getQualifiedClassName(packet), packet);
            }

            return;

            // if (true)
            // {
            // return;
            // }

            if (packet.getPacketId() == -484994657 && packet.targets) {
                packet.staticHitPoint.x = 0;
                packet.staticHitPoint.y = 0;
                packet.staticHitPoint.z = 0;

                packet.var_782.pop();
                packet.targetHitPoints.pop();
                packet.var_2638.pop();

                packet.name_48.pop();
                packet.targets.pop();

                for each (var tankData:* in Utils.getAvailableTankDatas(false))
                {
                    packet.targets.push(tankData.userName);
                    packet.name_48.push(tankData.tank.incarnation);

                    packet.var_782.push(packet.staticHitPoint);
                    packet.targetHitPoints.push(packet.staticHitPoint);
                    packet.var_2638.push(packet.staticHitPoint);
                }

                packet.var_782.push(packet.staticHitPoint);
                packet.targetHitPoints.push(packet.staticHitPoint);
                packet.var_2638.push(packet.staticHitPoint);
            }

            if (packet.getPacketId() == 1395251766)
            {
                packet.targets.pop();
                packet.var_1019.pop();

                for each (var td:* in Utils.getAvailableTankDatas(false))
                {
                    /* TODO: Only add tanks which are in a certain range. */
                    // trace("", tank.incarnation, tank.tankData.userName);
                    packet.targets.push(td.userName);
                    packet.var_1019.push(td.tank.incarnation);
                }
            }
        }

        public static function sendPacket(packet:*):void
        {
            const CNetwork:* = Utils.getTanksDefinition('scpacker.networking.Network') as Class;
            const network:* = Utils.osgiGetService(CNetwork);
            network.send(packet);
        }

        public static function weaponShotSmokey(targetName:String, incarnation:int):void
        {
            const CVector3d:Class = Utils.getTanksDefinition("package_329.class_1207");
            const vectorZero:* = new CVector3d(0, 0, 0);

            const CSmokeyShotPacket:Class = Utils.getTanksDefinition("package_300.class_1043");
            const packet:* = new CSmokeyShotPacket(getTimer(), targetName, incarnation, vectorZero, vectorZero, vectorZero);
            sendPacket(packet);
        }

        public static function setupLogFile():void {
            const date: Date = new Date();
            //const file: File = File.workingDirectory.resolvePath("logs/" + date.getFullYear() + "_" + (date.getMonth() + 1) + "_" + date.getDate() + "_" + date.getHours() + "_" + date.getMinutes() + "_log.txt");
            //logFile = new FileStream();
            //logFile.open(file, FileMode.UPDATE);
        }
    }
}