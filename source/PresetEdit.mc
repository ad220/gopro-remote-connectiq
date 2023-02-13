import Toybox.WatchUi;

//TODO: change names
//TODO: maybe just override a save method in GoProSettings

class PresetEditMenu extends SettingPickerMenu {
    public function initialize(_gp as GoProPreset, id) {
        SettingPickerMenu.initialize(_gp, id);
    }
}

class PresetEditItem extends SettingPickerItem {
    public function initialize() {
    }
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