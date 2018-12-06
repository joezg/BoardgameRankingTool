import { getRandomInt } from "./utils";

class RankingTool {
    constructor(listToRank) {
        this.init(listToRank);
    }

    init = (listToRank) => {
        this.items = listToRank.map((item) => ({
            item, score: 1, lostBy: null, finalPosition: null
        }))

        this.currentPosition = 1;
    }

    next = (numberToChoseFrom = 2) => {

        const candidates = this.items.filter( item => item.lostBy === null && item.finalPosition === null );
        
        if (candidates.length === 0){
            return false;
        }

        if (candidates.length === 1){
            const winner = candidates[0];
            winner.finalPosition = this.currentPosition;
            this.currentPosition++;

            this.items.forEach(item => {
                item.lostBy === winner && (item.lostBy = null);
            });

            return this.next();
        }

        candidates.sort((itemA, itemB) => itemA.score - itemB.score );

        return candidates.splice(0, numberToChoseFrom);
    }

    resolveMatchup = (winner, ...losers) => {
        losers.forEach((loser) => {
            winner.score += loser.score;
            loser.lostBy = winner 
        });
    }
}

export default RankingTool;