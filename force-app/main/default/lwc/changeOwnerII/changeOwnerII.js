import { LightningElement, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getUsers from '@salesforce/apex/ReassignRecordPageController.getUsers';
import updateRecords from '@salesforce/apex/ReassignRecordPageController.updateRecords';

export default class ChangeOwnerII extends LightningElement {
    __orgUsers__ = [];
    __oldOwnerId__ = '';
    __newOwnerId__ = '';
    __objectsToUpdate__ = [];
    __enableEmails__ = false;
    __notes__ = '';

    isReassignButtonDisabled = false;
    isPageDisabled = false;
    disabledPageAltText = '';

    connectedCallback() {
        getUsers()
            .then(userList => {
                this.__orgUsers__ = userList;
            })
            .catch(error => {
                this.exceptionHandler(error, 'ROOT CMP');
            });
    }

    onEnableEmailUpdateHandler(event) {
        this.__enableEmails__ = event.detail.checked;
    }

    onNotesChangeHandler(event) {
        this.__notes__ = event.detail;
    }

    onOldOwnerChangeHandler(event) {
        this.__oldOwnerId__ = event.detail;
    }

    onNewOwnerChangeHandler(event) {
        this.__newOwnerId__ = event.detail;
    }

    onObjectsChangeHandler(event) {
        this.__objectsToUpdate__ = event.detail;
    }

    onObjectFormExceptionHandler(event) {
        this.exceptionHandler(event.detail, 'OBJECT FORM');
    }

    onReassignClickHandler(event) {
        this.isReassignButtonDisabled = true;
        const oldOwner = this.getUserById(this.__oldOwnerId__);
        const newOwner = this.getUserById(this.__newOwnerId__);
        const objectsToUpdate = this.__objectsToUpdate__;
        if (!this.validateForm(oldOwner, newOwner, objectsToUpdate)) {
            this.isReassignButtonDisabled = false;
            return;
        }
        updateRecords({
            currentOwner: oldOwner,
            newOwner: newOwner,
            objectList: objectsToUpdate,
            enableEmails: this.__enableEmails__,
            notes: this.__notes__
        })
            .then(response => {
                this.onUpdateRecordsResponse(response);
                this.isReassignButtonDisabled = false;
            })
            .catch(error => {
                this.exceptionHandler(error,  'UPDATE REQ');
                this.isReassignButtonDisabled = false;
            })
    }

    getUserById(id) {
        let user;
        for (let i = 0; i < this.__orgUsers__.length; i++) {
            if (this.__orgUsers__[i].Id == id) {
                user = this.__orgUsers__[i];
                break;
            }
        }
        return user;
    }

    validateForm(oldOwner, newOwner, objectsToUpdate) {
        const toastVariant = 'warning';
        let toastEvent;
        if (!oldOwner) {
            toastEvent = new ShowToastEvent({
                variant: toastVariant,
                title: 'Invalid current owner',
                message: 'Empty owner field is not allowed. Click Select to search for user' 
            });
            this.dispatchEvent(toastEvent);
            return false;
        }
        if (!newOwner) {
            toastEvent = new ShowToastEvent({
                variant: toastVariant,
                title: 'Invalid new owner',
                message: 'Empty owner field is not allowed. Click Select to search for user'
            });
            this.dispatchEvent(toastEvent);
            return false;
        }
        if (!objectsToUpdate || objectsToUpdate.length == 0) {
            toastEvent = new ShowToastEvent({
                variant: toastVariant,
                title: 'Invalid objects list',
                message: 'Empty list of objects to update is not allowed. Please select objects'
            });
            this.dispatchEvent(toastEvent);
            return false;
        }
        return true;
    }

    onUpdateRecordsResponse(response) {
        let toastEvent;
        if (response) {
            toastEvent = new ShowToastEvent({
                variant: 'success',
                title: 'Success',
                message: 'Updating records has been initiated'
            });
        }
        else {
            toastEvent = new ShowToastEvent({
                variant: 'error',
                title: 'Error',
                message: 'Update request denied'
            });
        }
        this.dispatchEvent(toastEvent);
    }

    exceptionHandler(error, source) {
        console.log(source + ' ERROR: ' + JSON.stringify(error));
        if (source == 'UPDATE REQ') return;
        if (this.isPageDisabled) return;
        this.isPageDisabled = true;
        try {
            this.disabledPageAltText = 'Failed to access server. ' 
                + error.body.message;
        }
        catch (e) {
            this.disabledPageAltText = 'Failed to load the page';
        }
    }
}