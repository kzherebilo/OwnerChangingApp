import { api, LightningElement } from 'lwc';
import getObjects from '@salesforce/apex/ReassignRecordPageController.getObjects';

export default class Objectform extends LightningElement {
    __objectOptions__ = [];
    
    connectedCallback() {
        getObjects()
            .then(objectOptionList => {
                this.__objectOptions__ 
                    = this.parseObjectOptionList(objectOptionList);
            })
            .catch(error => {
                this.exceptionHandler(error);
            });
    }

    get objectOptions() {
        return this.__objectOptions__;
    }

    onObjectsChangeHandler(event) {
        const onObjectsChangeEvent = new CustomEvent('update', {
            detail: event.detail.value
        });
        this.dispatchEvent(onObjectsChangeEvent);
    }

    parseObjectOptionList(objectOptionList) {
        let parsedObjectList = [];
        if (!objectOptionList) return parsedObjectList;
        if (objectOptionList.length < 2) return parsedObjectList;
        let delimiter = objectOptionList[0];
        for(let i=1; i < objectOptionList.length; i++) {
            let objectOption = objectOptionList[i].split(delimiter);
            parsedObjectList.push({
                value: objectOption[0], label: objectOption[1]
            });
        }
        return parsedObjectList;
    }

    exceptionHandler(error) {
        const objectFormExceptionEvent = new CustomEvent('exception', {
            detail: error
        });
        this.dispatchEvent(objectFormExceptionEvent);
    }
}