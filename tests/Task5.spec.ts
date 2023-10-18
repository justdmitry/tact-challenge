import { Blockchain, SandboxContract } from '@ton-community/sandbox';
import '@ton-community/test-utils';
import { toNano, Address } from 'ton-core';
import { Task5 } from '../wrappers/Task5';
import { log } from 'console';

describe('Task5', () => {
    let blockchain: Blockchain;
    let task5: SandboxContract<Task5>;
    
    let seed1: bigint = 12345n;
    let seed2: bigint = 1234567n;
    let admin: Address = Address.parse("UQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAJKZ");

    beforeEach(async () => {
        blockchain = await Blockchain.create();
        task5 = blockchain.openContract(await Task5.fromInit(seed1, admin));
        const deployer = await blockchain.treasury('deployer');
        const deployResult = await task5.send(
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
            to: task5.address,
            deploy: true,
            success: true,
        });
    });

    it('have different addresses', async () => {
        let task5v2: SandboxContract<Task5> = blockchain.openContract(await Task5.fromInit(seed1, admin));
        let task5v3: SandboxContract<Task5> = blockchain.openContract(await Task5.fromInit(seed2, admin));
        
        let adr1: String = task5.address.toString();
        let adr2: String = task5v2.address.toString();
        let adr3: String = task5v3.address.toString();
        
        log("Task5 v1:", adr1);
        log("Task5 v2:", adr2);
        log("Task5 v3:", adr3);

        expect(adr1).toEqual(adr2);
        expect(adr1).not.toEqual(adr3);
    });
});



