import { api, LightningElement } from 'lwc';
import getObjects from '@salesforce/apex/ReassignRecordPageController.getObjects';

export default class Objectform extends LightningElement {
    _selectedObjects = [];
    _objectOptions = [];
    
    connectedCallback() {
        getObjects()
            .then(objectOptionList => {
                this._objectOptions = this.parseObjectOptionList(objectOptionList);
            })
            .catch(error => {
                this.exceptionHandler(error);
            });
    }

    @api
    get selectedObjects() {
        return this._selectedObjects;
    }

    get objectOptions() {
        return this._objectOptions;
    }

    handleChange(event) {
        this._selectedObjects = event.detail.value;
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

    esceptionHandler(error) {

    }
}