package dev.wolveringer
{
    import flash.system.ApplicationDomain;

    public class BattleManager
    {
        public static var instance: BattleManager;

        public var mapInitData:*;
        private var domain: ApplicationDomain;
        private var selectedBattleInfo: *;
        private var instantJoinBattleId: String;

        public function BattleManager(domain: ApplicationDomain) {
            this.domain = domain;
        }

        public function exitBattleWithoutNotify():void {
            this.instantJoinBattleId = null;

            const ILobbyLayoutService:Class = this.domain.getDefinition('projects.tanks.clients.fp10.libraries.tanksservices.service.layout.ILobbyLayoutService') as Class;
            const layoutService:* = Utils.osgiGetService(ILobbyLayoutService);
            layoutService.exitFromBattleWithoutNotify();
        }

        public function joinBattle(battleId:String): void {
            const IBattleLinkActivatorService:Class = this.domain.getDefinition('projects.tanks.clients.flash.commons.services.battlelinkactivator.IBattleLinkActivatorService') as Class;
            const battleLinkActivatorService:* = Utils.osgiGetService(IBattleLinkActivatorService);

            /* battle id, is remote battle url */
            battleLinkActivatorService.navigateToBattleUrlWithoutAvailableBattle(battleId, false);

            if(this.selectedBattleInfo && this.selectedBattleInfo.id === battleId) {
                this.joinSelectedBattle();
                this.instantJoinBattleId = null;
            } else {
                this.instantJoinBattleId = battleId;
            }
        }

        public function handleServerBattleSelected(itemId:String):void {
            const IBattleListFormService:Class = this.domain.getDefinition('alternativa.tanks.service.battlelist.IBattleListFormService') as Class;
            const battleListFormService:* = Utils.osgiGetService(IBattleListFormService);
            const item:* = battleListFormService.var_2697.__findBattleListItem(itemId);
            if(!item) {
                trace("Missing selected battle item", itemId);
                return;
            }

            this.selectedBattleInfo = item;
            if(item.id == this.instantJoinBattleId) {
                this.instantJoinBattleId = null;
                this.joinSelectedBattle();
                return;
            }
        }

        private function joinSelectedBattle(): void {
            const ETeam:Class = this.domain.getDefinition('package_332.class_1222') as Class;

            var targetTeam:*;
            if(this.selectedBattleInfo.battleMode.name == "DM") {
                /* just join */
                targetTeam = ETeam.NONE;
            } else {
                /* join the less team */
                if(this.selectedBattleInfo.reds > this.selectedBattleInfo.blues) {
                    targetTeam = ETeam.BLUE;
                } else {
                    targetTeam = ETeam.RED;
                }
            }

            trace("Joining battle " + this.selectedBattleInfo.id + " (Team: " + targetTeam.name + ")");
            const CPacketBattleJoin:* = this.domain.getDefinition('package_269.class_896') as Class;
            const CNetwork: * = this.domain.getDefinition('scpacker.networking.Network') as Class;
            const network:* = Utils.osgiGetService(CNetwork);
            network.send(new CPacketBattleJoin(targetTeam));
        }

        /* FIXME: Move into own class! */

        public function sendBattleInfo(): void {
            if(!this.mapInitData) {
                trace("Missing map init data");
                return;
            }
            
            const CLong: * = Utils.getTanksDefinition('alternativa.types.Long') as Class;
            const IResourceRegistry: * = Utils.getTanksDefinition('platform.client.fp10.core.registry.ResourceRegistry') as Class;
            const resourceRegistry: * = Utils.osgiGetService(IResourceRegistry);

            const mapId: int = this.mapInitData.mapId;
            const mapResource: * = resourceRegistry.getResource(CLong.getLong(0, mapId));
            if(!mapResource) {
                trace("missing map resource");
                return;
            }
            if(!mapResource.mapData) {
                trace("map resource not loaded");
                return;
            }

            ServerSocket.instance.sendSocketCommand("battle-info", {
                battleId: this.mapInitData.battleId,

                mapId: mapId,
                mapName: this.mapInitData.map_id,
                mapData: mapResource.mapData.toString()
            })
            trace("Send battle info for " + this.mapInitData.battleId + ". Map: " + mapId + "(" + this.mapInitData.map_id + ")");
        }
    }

}