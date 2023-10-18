import { Blockchain, SandboxContract } from '@ton-community/sandbox';
import '@ton-community/test-utils';
import { toNano } from 'ton-core';
import { Task4 } from '../wrappers/Task4';
import { log } from 'console';

describe('Task4', () => {
    let blockchain: Blockchain;
    let task4: SandboxContract<Task4>;

    let seed1: bigint = 12345n;
    let seed2: bigint = 1234567n;

    beforeEach(async () => {
        blockchain = await Blockchain.create();
        task4 = blockchain.openContract(await Task4.fromInit(seed1));
        const deployer = await blockchain.treasury('deployer');
        const deployResult = await task4.send(
            deployer.getSender(),
            {
                value: toNano('0.05'),
            },
            {
                $$type: 'Deploy',
                queryId: 0n,
            }
        );
        expect(deployResult.transactions).toHaveTransaction({
            from: deployer.address,
            to: task4.address,
            deploy: true,
            success: true,
        });
    });

    it('have different addresses', async () => {
        let task4v2: SandboxContract<Task4> = blockchain.openContract(await Task4.fromInit(seed1));
        let task4v3: SandboxContract<Task4> = blockchain.openContract(await Task4.fromInit(seed2));
        
        let adr1: String = task4.address.toString();
        let adr2: String = task4v2.address.toString();
        let adr3: String = task4v3.address.toString();
        
        log("Task4 v1:", adr1);
        log("Task4 v2:", adr2);
        log("Task4 v3:", adr3);

        expect(adr1).toEqual(adr2);
        expect(adr1).not.toEqual(adr3);
    });
});


