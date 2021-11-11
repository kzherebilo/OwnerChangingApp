import { api, LightningElement } from 'lwc';

export default class Userform extends LightningElement {
    __oldOwnerId__;
    __newOwnerId__;

    @api
    get oldOwnerId() {
        return this.__oldOwnerId__ ? this.__oldOwnerId__[0] : '';
    }
    onOldOwnerUpdateHandler(event) {
        this.__oldOwnerId__ = event.detail.value;
    }

    @api
    get newOwnerId() {
        return this.__newOwnerId__ ? this.__newOwnerId__[0] : '';
    }
    onNewOwnerUpdateHandler(event) {
        this.__newOwnerId__ = event.detail.value;
    }

}