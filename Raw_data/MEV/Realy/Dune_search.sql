### Realy Query


 WITH merge_blocks_pretable AS
 (
    SELECT 
        block.*
    FROM ethereum.blocks block
    WHERE number >= 15537394
),

txs_per_block AS
(
    SELECT 
        merge_blocks_pretable.`number`,
        count(*) as total_txns
    FROM merge_blocks_pretable
    INNER JOIN ethereum.transactions tx on tx.block_number = merge_blocks_pretable.`number`
    GROUP BY 1
),

merge_blocks AS
(
    SELECT 
        merge_blocks_pretable.*,
        total_txns
    FROM merge_blocks_pretable
    INNER JOIN txs_per_block on txs_per_block.`number` = merge_blocks_pretable.`number`
),

mev_boost_blocks AS
(
    SELECT 
        block.*,
        tx.`to` as validator_address,
        tx.value / (pow(10,18)) as payment
    FROM merge_blocks block
    INNER JOIN ethereum.transactions tx on tx.block_number = block.`number` and tx.`from` = block.miner and tx.`index` = block.total_txns - 1
),

mev_boost_blocks_pct AS
(
    SELECT 
        date_trunc('hour', merge_blocks.`time`) as time,
        CASE 
            WHEN mev_boost_blocks.miner = '0xb64a30399f7f6b0c154c2e7af0a3ec7b0a5b131a' OR
                 mev_boost_blocks.miner = '0xdafea492d9c6733ae3d56b7ed1adb60692c98bc5' THEN 'Flashbots Builder'
            WHEN mev_boost_blocks.miner = '0xf2f5c73fa04406b1995e397b55c24ab1f3ea726c' THEN 'Bloxroute (Max Profit)'
            WHEN mev_boost_blocks.miner = '0xf573d99385c05c23b24ed33de616ad16a43a0919' THEN 'Bloxroute (Ethical)'
            WHEN mev_boost_blocks.miner = '0x199d5ed7f45f4ee35960cf22eade2076e95b253f' THEN 'Bloxroute (Regulated)'
            WHEN mev_boost_blocks.miner = '0x199d5ed7f45f4ee35960cf22eade2076e95b253f' THEN 'Bloxroute (Regulated)'
            ELSE mev_boost_blocks.miner = '0xaab27b150451726ec7738aa1d0a94505c8729bd1' THEN  'Eden Network: Builder'
        END block_builder,
        SUM(mev_boost_blocks.payment) as validator_payment
    FROM merge_blocks
    LEFT JOIN mev_boost_blocks on mev_boost_blocks.number = merge_blocks.number
    GROUP BY 1,2
)

SELECT * FROM mev_boost_blocks_pct

