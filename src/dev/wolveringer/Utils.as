package dev.wolveringer
{
    import flash.utils.describeType;
    import jp.assasans.protanki.client.chainloader.Main;

    public class Utils {
        public static function getTanksDefinition(name:String):* {
            return Main.instance.loaderInfo.applicationDomain.getDefinition(name)
        }


        public static function osgiGetService(target:Class):*
        {
            const osgiClass:Class = getTanksDefinition('alternativa.osgi.OSGi') as Class;
            const osgi:* = osgiClass.getInstance();
            return osgi.getService(target);
        }

        public static function getAvailableTankDatas(includeLocal:Boolean = true):Vector.<*> {
            const result: Vector.<*> = new Vector.<*>();
            const CTankData:* = Utils.getTanksDefinition('alternativa.tanks.models.tank.class_1254') as Class;

            const IBattleService:Class = Utils.getTanksDefinition('alternativa.tanks.battle.BattleService') as Class;
            const battleService:* = Utils.osgiGetService(IBattleService);    
            if(!battleService) {
                return result;
            }

            for each(var body:* in battleService.method_296().method_1312().getTankBodies()) {
                /* Works only in a rectain range leider */
                const tankData:* = body.body.tank.tankData;
                if(tankData == CTankData["var_2846"] && !includeLocal) {
                    continue;
                }

                result.push(tankData);
                // packet.targets.push(tank.tankData.userName);
                // packet.var_1019.push(tank.incarnation);
            }

            return result;
        }


        public static function inspectObject(target:*, depth:Number = 1, prefix:String = ""):void
        {
            if (depth <= 0)
            {
                return;
            }

            const xml:XML = new XML(describeType(target));
            for each (var variable:XML in xml.variable)
            {
                const varName:String = variable.attribute("name");
                trace(prefix + " " + varName + " (" + variable.attribute("type") + "): " + target[varName]);
                if (target[varName] is Object)
                {
                    inspectObject(target[varName], depth - 1, prefix + " ");
                }
            }
        }

        public static function matrix4ToJson(matrix4:*):*
        {
            if(!matrix4) {
                return null;
            }

            return {
                    m00: matrix4.m00,
                    m01: matrix4.m01,
                    m02: matrix4.m02,
                    m03: matrix4.m03,

                    m10: matrix4.m10,
                    m11: matrix4.m11,
                    m12: matrix4.m12,
                    m13: matrix4.m13,

                    m20: matrix4.m20,
                    m21: matrix4.m21,
                    m22: matrix4.m22,
                    m23: matrix4.m23
            };
        }
        
        public static function quaternionToJson(quaternion:*):*
        {
            return {
                    "x": quaternion.x,
                    "y": quaternion.y,
                    "z": quaternion.z,
                    "w": quaternion.w
                };
        }

        public static function vector3ToJson(vec3:*):*
        {
            return {
                    "x": vec3.x,
                    "y": vec3.y,
                    "z": vec3.z
            };
        }
    }
}