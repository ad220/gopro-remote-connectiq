import Toybox.WatchUi;

//TODO: change names

class PresetEditMenu extends SettingPickerMenu {
    public function initialize(_gp as GoProPreset) {
        SettingPickerMenu.initialize(_gp);
    }
}

class PresetEditItem extends SettingPickerItem {
    
}

class PresetEditDelegate extends SettingPickerDelegate {

    public function initialize(_gp as GoProPreset) {
        SettingPickerDelegate.initialize(_gp);
    }

    public function onBack() as Void {
        gp.savePreset();
        SettingEditDelegate.onBack();
    }
}