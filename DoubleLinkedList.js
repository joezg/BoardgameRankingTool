class DoubleLinkedList {
    constructor(){
        this.first = null;
        this.last = null;
    }

    prepend(item){
        this.first = {
            value: item,
            next: this.first !== null ? this.first : null,
            previous: null
        }

        if (this.last === null){
            this.last = this.first;
        }
    }

    append(item){
        this.last = {
            value: item,
            previous: this.last !== null ? this.last : null,
            next: null
        }

        if (this.first === null){
            this.first = this.last;
        }
    }
    
}