import { shuffle } from "./utils";
import "./polyfill";

class RankingTool {
    constructor(listToRank, options = {}) {
        const { highestFirst = true, itemsInMatchup = 0 } = options;

        this.highestFirst = highestFirst;
        this.itemsInMatchup = itemsInMatchup;
        this.init(listToRank);
    }

    init = (listToRank) => {
        this.items = listToRank.map((item) => ({
            item, score: 1, eliminatedBy: null, finalPosition: null
        }))

        shuffle(this.items); //this is important for not hitting the worst case when ordered is (nearly) sorted

        if (this.highestFirst){
            this.currentPosition = 1;
        } else {
            this.currentPosition = this.items.length;
        }
    }

    next = () => {

        const candidates = this.items.filter( item => item.eliminatedBy === null && item.finalPosition === null );
        
        if (candidates.length === 0){
            return false;
        }

        if (candidates.length === 1){
            const last = candidates[0];
            last.finalPosition = this.currentPosition;
            this.currentPosition += this.highestFirst ? 1 : -1;

            this.items.forEach(item => {
                if (Array.isArray(item.eliminatedBy)){
                    item.eliminatedBy.includes(last) && (item.eliminatedBy = null);
                } else {
                    item.eliminatedBy === last && (item.eliminatedBy = null);
                }
            });

            return this.next();
        }

        candidates.sort((itemA, itemB) => itemB.score - itemA.score );

        return candidates.splice(0, this.itemsInMatchup);
    }

    resolveWithPickup = (picked, ...others) => {
        others.forEach((other) => {
            picked.score += other.score;
            other.eliminatedBy = picked 
        });
    }

    resolveWithOrder = (ordered) => {
        for (let i = ordered.length - 2; i >= 0; i--) {
            ordered[i].score += ordered[i+1].score;
            ordered[i+1].eliminatedBy = ordered[i];
        }
    }

    getResult() {
        this.items.sort((itemA, itemB) => itemA.finalPosition - itemB.finalPosition);
        return this.items;
    }
}

export default RankingTool;