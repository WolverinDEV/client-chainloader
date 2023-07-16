package jp.assasans.protanki.client.chainloader
{
    import flash.display.Loader;
    import flash.display.LoaderInfo;
    //import flash.display.NativeWindow;
    import flash.display.Screen;
    import flash.display.Sprite;
    import flash.display.StageAlign;
    import flash.display.StageScaleMode;
    import flash.events.Event;
    import flash.geom.Point;
    import flash.geom.Rectangle;
    import flash.net.URLLoader;
    import flash.net.URLRequest;
    import flash.system.ApplicationDomain;
    import flash.system.LoaderContext;
    import flash.system.Security;
    import flash.utils.ByteArray;
    import flash.utils.setInterval;
    import flash.events.KeyboardEvent;
    import dev.wolveringer.ServerSocket;
    import dev.wolveringer.BattleManager;
    import dev.wolveringer.RenderToggle;
    import dev.wolveringer.PacketHandler;
    import dev.wolveringer.Utils;
    import dev.wolveringer.HookCallbacks;
    import flash.utils.clearInterval;
    import flash.events.UncaughtErrorEvent;
    import flash.events.ErrorEvent;
    import flash.external.ExternalInterface;
    import flash.media.CameraRollBrowseOptions;
    import flash.utils.describeType;

    public class Main extends Sprite
    {
        public static var instance:Main;
        private var loader:Loader;
        private var game:*;
        private var socket:ServerSocket;
        private var timerFireToggle:Number = 0;
        private var intervalSmokyShot:Number = 0;
        private var initParameters:*;

        public function Main()
        {
            super();
            trace("Hello World?");

            Main.instance = this;
            addEventListener(Event.ADDED_TO_STAGE, this.init);

            ServerSocket.instance = new ServerSocket("localhost", 1336);
            ServerSocket.instance.registerCommandHandler("query-battle-info", this.cmdQueryBattleInfo);
            ServerSocket.instance.registerCommandHandler("tank-move", this.cmdSocketTankMove);
            ServerSocket.instance.registerCommandHandler("setup-bot-move", this.cmdSocketSetupBotMove);
            ServerSocket.instance.registerCommandHandler("garage-mount", this.cmdSocketGarageMount);
            ServerSocket.instance.registerCommandHandler("garage-buy", this.cmdSocketGarageBuy);
            ServerSocket.instance.registerCommandHandler("shot-smoky", this.cmdSocketShotSmoky);
            ServerSocket.instance.registerCommandHandler("weapon-smoky-shot", this.cmdSocketWeaponSmokyShot);
            ServerSocket.instance.registerCommandHandler("battle-leave", this.cmdSocketBattleLeave);
            ServerSocket.instance.registerCommandHandler("battle-join", this.cmdSocketBattleJoin);

            BattleManager.instance = new BattleManager(this.loaderInfo.applicationDomain);
            RenderToggle.instance = new RenderToggle(this.loaderInfo.applicationDomain);

            HookCallbacks.initialize();
            PacketHandler.setupLogFile();
        }

        private function init(event:Event):void
        {
            removeEventListener(Event.ADDED_TO_STAGE, this.init);

            // TODO(Assasans): Flash Player prohibits the use local files with network support.
            try
            {
                Security.allowDomain('*');
            }
            catch (error)
            {
                // Throws SecurityError in AIR
            }

            //this.initParameters = loaderInfo.parameters;
            this.initParameters = {
                "locale": "en",
                "library": "https://did.science/230619_library_win.swf?q=" + (new Date().getTime()),
                "server": "146.59.110.195:1337",
                "resources": "http://146.59.110.103"
            };

            const request:URLRequest = new URLRequest(initParameters['library']);
            const loader:URLLoader = new URLLoader();
            loader.dataFormat = 'binary';
            loader.addEventListener(Event.COMPLETE, this.byteArrayLoadComplete);
            loader.load(request);
        }

        private function byteArrayLoadComplete(event:Event):void
        {
            const bytes:ByteArray = (event.target as URLLoader).data as ByteArray;

            this.loader = new Loader();
            this.loader.contentLoaderInfo.addEventListener(Event.COMPLETE, this.onComplete);

            if (initParameters['control-server'] === "yes")
            {
                trace("Control server connect");
                ServerSocket.instance.connect();
            }

            const serverEndpoint:Vector.<String> = Vector.<String>(initParameters['server'].split(':'));
            const parameters:Object = {
                lang: initParameters['locale'],
                ip: serverEndpoint[0],
                port: serverEndpoint[1],
                resources: initParameters['resources'],
                debug: "1",
                showlog: "*"
            };

            const context:LoaderContext = new LoaderContext(false, ApplicationDomain.currentDomain);
            context.parameters = parameters;
            context.allowCodeImport = true;
            this.loader.loadBytes(bytes, context);
        }

        private function onComplete(event:Event):void
        {
            this.loader.removeEventListener(Event.COMPLETE, this.onComplete);

            stage.stageFocusRect = false;
            stage.align = StageAlign.TOP_LEFT;
            stage.scaleMode = StageScaleMode.NO_SCALE;

            // Resize window if running in AIR
            const nativeWindow /*:NativeWindow */ = "nativeWindow" in stage ? stage.nativeWindow : null;
            if (nativeWindow)
            {
                const bounds:Rectangle = nativeWindow.bounds;
                const screen:Screen = Screen.getScreensForRectangle(bounds)[0];

                /* min tanks res (hard coded in tanks) */
                stage.stageWidth = 970;
                stage.stageHeight = 630;

                nativeWindow.minSize = new Point(970, 630);
                nativeWindow.x = (screen.bounds.width - nativeWindow.width) / 2;
                nativeWindow.y = (screen.bounds.height - nativeWindow.height) / 2;

                if ("window-position" in this.initParameters && this.initParameters["window-position"])
                {
                    const windowPos:Array = this.initParameters["window-position"].split(":");
                    nativeWindow.x = parseInt(windowPos[0]);
                    nativeWindow.y = parseInt(windowPos[1]);
                    trace("Setting win positon");
                }
            }

            const loaderInfo:LoaderInfo = this.loader.contentLoaderInfo as LoaderInfo;
            loaderInfo.uncaughtErrorEvents.addEventListener(UncaughtErrorEvent.UNCAUGHT_ERROR, function(event:UncaughtErrorEvent):void
            {
                var errorText:String;
                var stack:String;
                if (event.error is Error)
                {
                    errorText = (event.error as Error).message;
                    stack = (event.error as Error).getStackTrace();
                    if (stack != null)
                    {
                        errorText += stack;
                    }
                }
                else if (event.error is ErrorEvent)
                {
                    errorText = (event.error as ErrorEvent).text;
                }
                else
                {
                    errorText = event.text;
                }
                event.preventDefault();
                trace(errorText + " " + event.error, "Error");
            });

            const gameClass:Class = loaderInfo.applicationDomain.getDefinition('Game') as Class;
            this.game = new gameClass();

            const gameLoader:Sprite = new Sprite();
            const prelauncher:Sprite = new Sprite();

            {
                //const CSwiftSuspendersInjector:Class = Utils.getTanksDefinition("org.robotlegs.adapters.SwiftSuspendersInjector");
                const CSwiftSuspendersInjector:Class = Utils.getTanksDefinition("org.swiftsuspenders.Injector");
                const injector:* = new CSwiftSuspendersInjector();

                const CEntranceViewMediator: Class = Utils.getTanksDefinition("alternativa.tanks.view.EntranceViewMediator");
                // trace(describeType(CEntranceViewMediator).toString());
                
                // var description:XML = describeType(CEntranceViewMediator);
                // for each(var node in description.factory.*) {
                //     if(!(node.name() == "variable" || node.name() == "accessor")) {
                //         continue;
                //     }

                //     for each(var n in node.metadata.(@name == "Inject")) {
                //         trace(node.name() + " -> " + n.parent().@name);
                //     }
                // }

                const info:* = injector.__getInjectionPoints(CEntranceViewMediator);
                trace("alternativa.tanks.view.EntranceViewMediator inspect");
                Utils.inspectObject(
                    info,
                    5
                );
            }

            // StandaloneLoader (this) -> Prelauncher -> Loader (gameLoader) -> Game
            addChild(prelauncher);
            prelauncher.addChild(gameLoader);
            gameLoader.addChild(game);

            if(nativeWindow && false) {
                this.game.SUPER(stage, this, loaderInfo);
            } else {
                const serverEndpoint:Vector.<String> = Vector.<String>(initParameters['server'].split(':'));
                this.game.SUPER(stage, this, {
                    parameters: {
                        lang: initParameters['locale'],
                        ip: serverEndpoint[0],
                        port: serverEndpoint[1],
                        resources: initParameters['resources'],
                        debug: "1",
                        showlog: "*"
                    }
                });
            }
            

            // if (nativeWindow)
            // {
            // nativeWindow.title = 'ProTanki [BotLoaded]';
            // }

            const ICommandService:Class = loaderInfo.applicationDomain.getDefinition('alternativa.osgi.service.command.CommandService') as Class;
            const serviceCommand:* = Utils.osgiGetService(ICommandService);
            serviceCommand.registerCommand("inject", "hello", "Inject says hello", [], this.cmdInjectHello);

            const self:Main = this;
            serviceCommand.registerCommand("inject", "send-map", "Send map info", [], function():*
            {
                BattleManager.instance.sendBattleInfo();
            });
            serviceCommand.registerCommand("inject", "ta", "Set the turn acceleration", [Number], function(param1:*, a:Number):*
            {
                var tankContainer:* = getLocalTankContainer();
                if (!tankContainer)
                {
                    param1.addText("No tank");
                    return;
                }

                tankContainer.tank.setTurnAcceleration(a);
                param1.addText("Updated");
            });
            serviceCommand.registerCommand("inject", "ma", "Set the move acceleration", [Number], function(param1:*, a:Number):*
            {
                var tankContainer:* = getLocalTankContainer();
                if (!tankContainer)
                {
                    param1.addText("No tank");
                    return;
                }

                tankContainer.tank.method_2493(a);
                param1.addText("Updated");
            });
            serviceCommand.registerCommand("inject", "tm", "Set the tank mass", [Number], function(param1:*, a:Number):*
            {
                var tankContainer:* = getLocalTankContainer();
                if (!tankContainer)
                {
                    param1.addText("No tank");
                    return;
                }

                const original:Number = tankContainer.tank.method_382().mass;
                tankContainer.tank.method_382().mass = a;
                param1.addText("Updated from " + original);
            });
            serviceCommand.registerCommand("inject", "wg", "Set word gravity (Attention MemHack protection)", [Number], function(param1:*, a:Number):*
            {
                var tankContainer:* = getLocalTankContainer();
                if (!tankContainer)
                {
                    param1.addText("No tank");
                    return;
                }

                const gravity:* = tankContainer.tank.method_382().scene.gravity;
                const original:Number = gravity.z;
                gravity.z = a;
                param1.addText("Updated from " + original);
            });
            serviceCommand.registerCommand("inject", "mms", "Update the max move speed", [Number], function(param1:*, a:Number):*
            {
                var tankContainer:* = getLocalTankContainer();
                if (!tankContainer)
                {
                    param1.addText("No tank");
                    return;
                }

                const gravity:* = tankContainer.tank.method_2294(a, false);
                param1.addText("Updated");
            });
            serviceCommand.registerCommand("inject", "q", "Exit current battle", [], function(param1:*):*
            {
                BattleManager.instance.exitBattleWithoutNotify();
            });

            serviceCommand.registerCommand("inject", "j", "Join battle (BattleId)", [String], function(param1:*, battleId:String):void
            {
                BattleManager.instance.joinBattle(battleId);
            });

            serviceCommand.registerCommand("inject", "ms", "Mount the smokey", [], function(param1:*):void
            {
                const CPacketGarageMountItem:* = Utils.getTanksDefinition("package_259.class_833");
                PacketHandler.sendPacket(new CPacketGarageMountItem("smoky_m0"));
            });

            serviceCommand.registerCommand("inject", "tc", "Toggle Camera", [String], function(param1:*, enabledFlag:String):void
            {
                const IBattleService:Class = loaderInfo.applicationDomain.getDefinition('alternativa.tanks.battle.BattleService') as Class;
                const battleService:* = osgiGetService(IBattleService);
                if (!battleService)
                {
                    param1.addText("No battle service");
                    return;
                }

                const enabled:Boolean = enabledFlag !== "0" && enabledFlag !== "false";
                if (enabled)
                {
                    param1.addText("Enabled 3d renderer");
                    battleService.method_2203().method_1356();
                }
                else
                {
                    param1.addText("Disabled 3d renderer");
                    battleService.method_2203().method_2027();
                }
            });

            /* resets the battle timeout timer */
            setInterval(this.unpauseGame, 1000);
            // setInterval(function():void
            // {
            //     /* Close all popup windows */
            //     const IDialogWindowsDispatcherService:* = Utils.getTanksDefinition("projects.tanks.clients.fp10.libraries.tanksservices.service.dialogwindowdispatcher.IDialogWindowsDispatcherService");
            //     const windowsDispatcherService:* = Utils.osgiGetService(IDialogWindowsDispatcherService);
            //     if (windowsDispatcherService.isOpen())
            //     {
            //         windowsDispatcherService.close();
            //     }
            // }, 1000);
        }

        /*
         * Remove the in game pause time overlay as well as allow the tank beein controlled
         * when the window is not focused.
         * Attention: The server keeps track of the users pause by using the control key flags send in move packets.
         *            If there are no control keys pressed for over 5 min the server will kick the client.
         */
        private function unpauseGame():void
        {
            return; // FIXME: Class names have changed!

            const IBattlePauseSupport:Class = loaderInfo.applicationDomain.getDefinition('package_110.class_284') as Class;
            const battlePauseSupport:* = osgiGetService(IBattlePauseSupport);

            // handleBattleEvent
            if (!battlePauseSupport || !battlePauseSupport.getPauseSupport())
            {
                /* game can not be paused */
                return;
            }

            const pauseSupport:* = battlePauseSupport.getPauseSupport();
            const IBattleEventIndicatorShown:Class = loaderInfo.applicationDomain.getDefinition('package_349.class_1458') as Class;

            /* this will cause the pause menu to close */
            pauseSupport.handleBattleEvent(new IBattleEventIndicatorShown());
        }

        private function cmdInjectHello(param1:*):void
        {
            param1.addText("Inject hello world!");
        }

        private function osgiGetService(target:Class):*
        {
            const osgiClass:Class = loaderInfo.applicationDomain.getDefinition('alternativa.osgi.OSGi') as Class;
            const osgi:* = osgiClass.getInstance();
            return osgi.getService(target);
        }

        private function getLocalTankContainer():*
        {
            const clazz:* = loaderInfo.applicationDomain.getDefinition('alternativa.tanks.models.tank.class_1254') as Class;
            return clazz["var_2846"];
        }

        private function fireFireReleaseEvent():void
        {
            var event:KeyboardEvent = new KeyboardEvent(
                KeyboardEvent.KEY_UP,
                false,
                false,
                32,
                32,
                0
                );
            Main.instance.stage.dispatchEvent(event);
        }

        private function cmdSocketBattleLeave(payload:*):void
        {
            BattleManager.instance.exitBattleWithoutNotify();
        }

        private function cmdSocketBattleJoin(payload:*):void
        {
            BattleManager.instance.joinBattle(payload.battleId);
        }

        private function cmdSocketShotSmoky(payload:*):void
        {

        }

        private function cmdSocketWeaponSmokyShot(payload:*):void
        {
            if (this.intervalSmokyShot > 0)
            {
                clearInterval(this.intervalSmokyShot);
                this.intervalSmokyShot = 0;
            }

            if (!payload.enabled)
            {
                return;
            }

            const CTankState:* = Utils.getTanksDefinition("alternativa.tanks.battle.objects.tank.class_1396");
            this.intervalSmokyShot = setInterval(function():void
            {
                var targetTankData:* = null;
                var targetTankDistance:int = 1e9;

                const localTank:* = getLocalTankContainer();
                if (!localTank)
                {
                    /* we're not in game */
                    return;
                }

                const localPosition:* = getLocalTankContainer().tank.method_1005().body.state.position;
                for each (var td:* in Utils.getAvailableTankDatas(false))
                {
                    if (("filter" in payload) && td.userName.indexOf(payload.filter) < 0)
                    {
                        continue;
                    }

                    if (td.health <= 0)
                    {
                        /* do not shoot him :) */
                        continue;
                    }

                    if (td.spawnState != CTankState.const_1079)
                    {
                        /* tank is newcome (const_4) or dead (DEAD) */
                        continue;
                    }

                    const tankPosition:* = td.tank.method_1005().body.state.position;
                    var distance:Number = Math.sqrt(
                        (tankPosition.x - localPosition.x) * (tankPosition.x - localPosition.x) +
                        (tankPosition.y - localPosition.y) * (tankPosition.y - localPosition.y)
                        );
                    if (distance < targetTankDistance)
                    {
                        targetTankDistance = distance;
                        targetTankData = td;
                    }
                }

                if (!targetTankData)
                {
                    return;
                }
                PacketHandler.weaponShotSmokey(targetTankData.userName, targetTankData.tank.incarnation);
            }, 1848);
        }

        private function cmdSocketGarageMount(payload:*):void
        {
            trace("Mounting " + payload.item);
            const CPacketGarageMountItem:* = Utils.getTanksDefinition("package_259.class_833");
            PacketHandler.sendPacket(new CPacketGarageMountItem(payload.item));
        }

        private function cmdSocketGarageBuy(payload:*):void
        {
            trace("Buying " + payload.item + " (for: " + payload.price + ")");
            const C2SGarageBuyItem:* = Utils.getTanksDefinition("package_259.class_950");
            PacketHandler.sendPacket(new C2SGarageBuyItem(payload.item, 1, payload.price));
        }

        private function cmdSocketSetupBotMove(payload:*):void
        {
            var tankContainer:* = getLocalTankContainer();
            if (!tankContainer)
            {
                trace("No tank");
                return;
            }

            tankContainer.tank.setTurnAcceleration(5000);
        }

        private function cmdSocketTankMove(param1:*):void
        {
            const tankContainer:* = this.getLocalTankContainer();
            if (!tankContainer)
            {
                return;
            }

            const clientObject:* = tankContainer.tank.method_1284();
            if (!clientObject)
            {
                trace("Missing client object");
                return;
            }

            const CChassiController:* = loaderInfo.applicationDomain.getDefinition('package_11.class_38') as Class;
            const chassiController:* = clientObject.getParams(CChassiController);
            if (!chassiController)
            {
                trace("Missing chassi controller");
                return;
            }

            var flags:Number = 0;
            if (param1.forward == 1)
            {
                flags |= 0x01;
            }
            else if (param1.forward == -1)
            {
                flags |= 0x02;
            }

            if (param1.rotate == 1)
            {
                flags |= 0x04;
            }
            else if (param1.rotate == -1)
            {
                flags |= 0x08;
            }

            chassiController.method_875(flags);
            // const currentFlags:Number = chassiController.method_1839();
            // if(currentFlags != flags) {
            // trace("Update from " + currentFlags + " to " + flags);
            // chassiController.method_875(flags);
            // }

            /* chassiController.method_875 should already call method_2086, but explicitly calling this reduces lag (idk why) */
            tankContainer.tank.method_2086(param1.forward, param1.rotate, param1.backwardsDriving);
        }

        private function cmdQueryBattleInfo(param1:*):void
        {
            BattleManager.instance.sendBattleInfo();
        }

        public static function afterPhysicsUpdated(battlePhysicsScene:*):void
        {
            const tankContainer:* = instance.getLocalTankContainer();
            if (!tankContainer)
            {
                ServerSocket.instance.sendSocketCommand("physics-updated", {
                        "local-tank": null
                    });
                return;
            }

            const body:* = tankContainer.tank.method_1005().body;
            const collisionBox:* = tankContainer.tank.method_130();
            ServerSocket.instance.sendSocketCommand(
                "tank-state",
                    {
                    "local-tank": {
                        position: Utils.vector3ToJson(body.state.position),
                        angularVelocity: Utils.vector3ToJson(body.state.angularVelocity),
                        velocity: Utils.vector3ToJson(body.state.velocity),
                        orientation: Utils.quaternionToJson(body.state.orientation),
                        collisionBox: Utils.vector3ToJson(collisionBox.hs)
                    }
                }
                );
        }

        // Bonus IDs can only be collected when being close enough to them
        // private function collectBonus(bonusId:String):void {
        // const CLong: * = loaderInfo.applicationDomain.getDefinition('alternativa.types.Long') as Class;
        // const CNetwork: * = loaderInfo.applicationDomain.getDefinition('scpacker.networking.Network') as Class;
        // const network:* = osgiGetService(CNetwork);

        // const CPacketCollectBonus: * = loaderInfo.applicationDomain.getDefinition('package_261.class_851') as Class;
        // network.send(new CPacketCollectBonus(bonusId));
        // trace("Sending collect for ", bonusId);
        // //Network(OSGi.getInstance().getService(Network)).send(new package_261.class_851(param1));
        // }
    }
}