import { abilityAccessCtrl, common, Permissions } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';

class PermissionHelper {

  private uiContext: common.UIAbilityContext | null = null;

  setUIContext(ctx: common.UIAbilityContext) {
    this.uiContext = ctx;
  }

  async requestPermissions(permissions: Array<Permissions>): Promise<boolean> {
    try {
      const atManager: abilityAccessCtrl.AtManager = abilityAccessCtrl.createAtManager();

      if (!this.uiContext) {
        console.error('[PermissionHelper] uiContext is null');
        return false;
      }

      const result = await atManager.requestPermissionsFromUser(this.uiContext, permissions);

      return !!result.authResults.length && result.authResults.every(v => v === 0);

    } catch (error) {
      const err = error as BusinessError;
      console.error(`[PermissionHelper] Failed: ${err.code} ${err.message}`);
      return false;
    }
  }
}

export default new PermissionHelper();
