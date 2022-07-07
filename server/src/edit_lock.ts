//Allows for locking of a key which can be cleared manually or
//will automatically clear after a timeout as well as query
//if a key is being actively locked
class EditLock {

    //Format is key: time
    editLocks = {};

    get (key: string): boolean {
        var value = this.editLocks[key];
        if (value !== undefined) {
            //300 seconds
            if (Date.now() - value <= 1000 * 300) {
                return true;
            }
        }
        return false;
    }

    set (key: string) {
        this.editLocks[key] = Date.now();
    }
    
    clear (key: string) {
        delete this.editLocks[key];
    }
}

export const editLock = new EditLock();