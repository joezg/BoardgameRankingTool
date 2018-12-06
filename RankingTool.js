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

    next = () => {
        const found = this.items.reduce((acc, item) => {
            if (item.lostBy === null && item.finalPosition === null){
                if (!acc.lowest || item.score <= acc.lowest.score){
                    acc.next = acc.lowest;
                    acc.lowest = item;
                } else if (!acc.next){
                    acc.next = item;
                }
            }

            return acc;
        }, {})

        if (!found.next){
            if (!found.lowest){
                return false;
            }
            const winner = found.lowest
            winner.finalPosition = this.currentPosition;
            this.currentPosition++;

            this.items.forEach(item => {
                item.lostBy === winner && (item.lostBy = null);
            });

            return this.next();
        }

        return [
            found.lowest, found.next
        ];
    }

    resolveMatchup = (winner, ...losers) => {
        winner.score += losers[0].score; //TODO
        losers.forEach((loser) => loser.lostBy = winner );
    }
}

export default RankingTool;