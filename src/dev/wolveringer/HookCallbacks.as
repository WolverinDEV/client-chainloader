package dev.wolveringer
{
    import flash.utils.ByteArray;
    import flash.external.ExternalInterface;
    import dev.wolveringer.Base64;
    import flash.utils.describeType;
    import flash.utils.getQualifiedClassName;

    public class HookCallbacks {
        public static function initialize(): void {
            if(ExternalInterface.available) {
                ExternalInterface.addCallback("__cl_data", function(payload:String):void {
                    const buffer: ByteArray = Base64.decodeToByteArray(payload);

                    const CNetwork:* = Utils.getTanksDefinition('scpacker.networking.Network') as Class;
                    const network:* = Utils.osgiGetService(CNetwork);
                    network.__data_received(buffer);
                })
            }
        }

        public static function fixupInjectionPoints(self:*, clazz:Class, description:*):void {
            const CPropertyInjectionPoint:Class = Utils.getTanksDefinition("org.swiftsuspenders.injectionpoints.PropertyInjectionPoint");
            const CMethodInjectionPoint:Class = Utils.getTanksDefinition("org.swiftsuspenders.injectionpoints.MethodInjectionPoint");

            if(description.injectionPoints.length > 0) {
                description.injectionPoints = [];
            }

            var classDescription:XML = describeType(clazz);
            var node:XML;
            var type:String;
            var name:String;

            for each(node in classDescription.factory.*.metadata.(@name == "Inject")) {
                type = node.parent().name();
                name = node.parent().@name;

                if(type == "variable" || type == "accessor") {
                    description.injectionPoints.push(
                        new CPropertyInjectionPoint(node)
                    );
                } else if(type == "method") {
                    description.injectionPoints.push(
                        new CMethodInjectionPoint(node, self)
                    );
                } else {
                    trace(" ", name, " ", type);
                }
            }
            
            for each(node in classDescription.factory.method.metadata.(@name == "PostConstruct")) {
                type = node.parent().name();
                name = node.parent().@name;

                if(type == "method") {
                    description.injectionPoints.push(
                        new CMethodInjectionPoint(node, self)
                    );
                } else {
                    trace(" ", name, " ", type);
                }
            }

            trace("Fixed inject", getQualifiedClassName(clazz), "->", description.injectionPoints.length);
        }

        // Hook callback functions
        public static function packetIncoming(packet:Object):Boolean
        {
            PacketHandler.packetIncoming(packet);
            return true;
        }

        public static function isConnected():Boolean {
            return true;
        }

        public static function packetOutgoing(packet:Object):Boolean
        {
            if(ExternalInterface.available) {
                const buffer: ByteArray = new ByteArray();
                packet.wrap(buffer);
                ExternalInterface.call("__cl_send_data", Base64.encodeByteArray(buffer));
            }
            
            const result:* = PacketHandler.packetOutgoing(packet);
            if(result == false) {
                return false;
            }

            return true;
        }

        public static function frameError(error:Error): void {
            trace("encountered frame error:")
            trace(error);
        }
    }
}