package dev.wolveringer
{
    import flash.events.Event;
    import flash.system.ApplicationDomain;
    import flash.text.TextField;
    import flash.text.TextFormat;
    import flash.text.TextFieldAutoSize;
    import jp.assasans.protanki.client.chainloader.Main;
    import flash.events.KeyboardEvent;
    import flash.display.Stage;
    import flash.utils.clearInterval;
    import flash.utils.setInterval;

    public class RenderToggle
    {
        public static var instance: RenderToggle;

        private var domain: ApplicationDomain;
        private var notifyTextField:TextField;
        private var enabled:Boolean = true;
        private var disableInterval:Number = 0;

        public function RenderToggle(domain: ApplicationDomain) {
            this.domain = domain;
            
            const textFormat: TextFormat = new TextFormat("Tahoma", 12, 0xFF0000);

            this.notifyTextField = new TextField();
            this.notifyTextField.defaultTextFormat = textFormat;
            this.notifyTextField.autoSize = TextFieldAutoSize.LEFT;
            this.notifyTextField.text = "3D RENDERER DISABLED!";
            this.notifyTextField.selectable = false;

            const self:RenderToggle = this;
            const stage:Stage = Main.instance.stage;
            stage.addEventListener(KeyboardEvent.KEY_DOWN, function(event:KeyboardEvent):void {
                if(event.keyCode == 105) {
                    self.SetState(!self.enabled);
                }
            });

            stage.addEventListener(Event.RESIZE, function(event:Event):void {
                self.centerTextField();
            });
            this.centerTextField();
        }

        private function centerTextField(): void {
            const stage:Stage = Main.instance.stage;
            const scale:int = Math.min(stage.stageWidth, stage.stageHeight * 2) / 240;
            notifyTextField.scaleX = scale;
            notifyTextField.scaleY = scale;

            notifyTextField.x = (stage.stageWidth - notifyTextField.textWidth * scale) / 2;
            notifyTextField.y = (stage.stageHeight - notifyTextField.textHeight * scale) / 2;
        }

        public function Enable():* {
            SetState(true);

        }

        public function Disable():* {
            /* 
             * Attention:
             * This needs to have class_1276.method_1483 (addEffect) patched by adding
             * a check whatever the class is disabled or not!
             */
            SetState(false);
        }

        private function SetState(state:Boolean):* {
            const IBattleService:Class = this.domain.getDefinition('alternativa.tanks.battle.BattleService') as Class;
            const battleService:* = osgiGetService(IBattleService);    
            if(!battleService) { return; }

            this.enabled = state;
            if(state) {
                Main.instance.stage.removeChild(this.notifyTextField);
                battleService.method_2203().method_1356();
                clearInterval(disableInterval);
                disableInterval = 0;
            } else {
                Main.instance.stage.addChild(this.notifyTextField);

                /* Use an interval as TO reenables it when joining a battle. */
                battleService.method_2203().method_2027();
                disableInterval = setInterval(function():void {
                    battleService.method_2203().method_2027();
                }, 1000);
            }
        }

        /* FIXME: Move into own class! */
        private function osgiGetService(target:Class):*
        {
            const osgiClass:Class = this.domain.getDefinition('alternativa.osgi.OSGi') as Class;
            const osgi:* = osgiClass.getInstance();
            return osgi.getService(target);
        }
    }

}