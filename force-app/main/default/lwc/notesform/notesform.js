import { api, LightningElement } from 'lwc';

export default class Notesform extends LightningElement {

    onNotesChangeHandler(event) {
        const onNotesChangeEvent = new CustomEvent('noteschange', {
            detail: event.detail.value
        });
        this.dispatchEvent(onNotesChangeEvent);
    }
}