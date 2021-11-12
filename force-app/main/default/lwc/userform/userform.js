import { api, LightningElement } from 'lwc';

export default class Userform extends LightningElement {

    onOldOwnerUpdateHandler(event) {
        const onOldOwnerChangeEvent = new CustomEvent('oldownerchange', {
            detail: event.detail.value[0]
        });
        this.dispatchEvent(onOldOwnerChangeEvent);
    }

    onNewOwnerUpdateHandler(event) {
        const onNewOwnerChangeEvent = new CustomEvent('newownerchange', {
            detail: event.detail.value[0]
        });
        this.dispatchEvent(onNewOwnerChangeEvent);
    }

}