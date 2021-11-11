import { LightningElement, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getUsers from '@salesforce/apex/ReassignRecordPageController.getUsers';
import updateRecords from '@salesforce/apex/ReassignRecordPageController.updateRecords';

export default class ChangeOwnerII extends LightningElement {
    __orgUsers__ = [];
    __enableEmails__ = false;

    isReassignButtonDisabled = false;

    connectedCallback() {
        getUsers()
            .then(userList => {
                this.__orgUsers__ = userList;
            })
            .catch(error => {
                this.exceptionHandler(error);
            });
    }

    onEnableEmailUpdateHandler(event) {
        this.__enableEmails__ = event.detail.checked;
        console.debug('emails ' + this.__enableEmails__);
    }

    onReassignClickHandler(event) {
        this.isReassignButtonDisabled = true;
        const userform = this.template.querySelector('c-userform');
        const oldOwner = this.getUserById(userform.oldOwnerId);
        const newOwner = this.getUserById(userform.newOwnerId);
        const objectsToUpdate
            = this.template.querySelector('c-objectform').selectedObjects;
        if (!this.validateForm(oldOwner, newOwner, objectsToUpdate)) {
            this.isReassignButtonDisabled = false;
            return;
        }
        updateRecords({
            currentOwner: oldOwner,
            newOwner: newOwner,
            objectList: objectsToUpdate,
            enableEmails: this.__enableEmails__
        })
            .then(result => {
                const toastEvent = new ShowToastEvent({
                    variant: 'info',
                    title: 'Success!',
                    message: 'Updating records has been initiated'
                });
                this.dispatchEvent(toastEvent);
                this.isReassignButtonDisabled = false;
            })
            .catch(error => {
                this.exceptionHandler(error);
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

    exceptionHandler(error) {
        console.log('ROOT_CMP_ERROR: ' + JSON.stringify(error));
    }
}