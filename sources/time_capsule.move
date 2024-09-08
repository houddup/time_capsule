
/// Module: time_capsule
module time_capsule::time_capsule {

    // 结构体用来存储文件数据
    public struct File has key, store {
        id: UID,
        file_data: vector<u8>,  // 存储文件的二进制数据
        file_name: vector<u8>,  // 文件名
    }

    // 存储文件函数
    public fun store_file(file_data: vector<u8>, file_name: vector<u8>, ctx: &mut TxContext) {
        let file = File {
            id: object::new(ctx),
            file_data,
            file_name,
        };
        transfer::public_transfer(file, tx_context::sender(ctx));
    }


    use blob_store::blob;
    use blob_store::blob::Blob;
    use blob_store::system::{System};
    use sui::coin::{Coin};
    use sui::sui::{SUI};
    use sui::bcs;

    const RED_STUFF: u8 = 0;


    #[allow(lint(self_transfer))]
    public fun write(system_obj: &mut System<SUI>, payment: Coin<SUI>, file_data: vector<u8>, ctx: &mut TxContext) {
        let mut encode = bcs::new(file_data);
        let root_hash = bcs::peel_u256(&mut encode);

        let (storage, change) = system_obj.reserve_space<SUI>(10_000_000, 3, payment, ctx);
        let blob_id = blob::derive_blob_id(root_hash, RED_STUFF, 10000);
        let blob1 = blob::register(system_obj, storage, blob_id, root_hash, 10000, RED_STUFF, ctx);

        transfer::public_transfer(blob1, tx_context::sender(ctx));
        transfer::public_transfer(change, tx_context::sender(ctx));
    }

    public struct WrappedBlob has key {
        id: UID,
        blob: Blob,
    }

    public fun wrap(blob: Blob, ctx: &mut TxContext): WrappedBlob {
        WrappedBlob { id: object::new(ctx), blob }
    }



    // -----------------------------------------------------

    use sui::tx_context::{Self, TxContext};
    use sui::object::{Self, UID};
    use sui::table::{Self, Table};
    use sui::address::Address;

    // 定义一个结构体，用于存储时间戳和 blobId
    public struct TimeEntry has key {
        id: UID,
        timestamp: u64,
        blobId: vector<u8>,
    }

    // 在合约中使用表来存储 TimeEntry 对象，key 是账户地址
    public struct TimeEntryStore has key {
        entries: Table<Address, TimeEntry>,  // 使用账户地址作为 key，TimeEntry 对象作为 value
    }

    // 初始化存储表的函数
    public fun init(ctx: &mut TxContext): TimeEntryStore {
        TimeEntryStore {
            entries: Table::new(ctx),  // 初始化一个空表
        }
    }

    // 存储时间戳和 blobId 的函数，不转移对象，而是存入合约
    public fun store_time_entry(
        store: &mut TimeEntryStore,  // 引用存储表
        timestamp: u64,
        blobId: vector<u8>,
        ctx: &mut TxContext
    ) {
        let account = tx_context::sender(ctx);  // 获取调用者的账户地址
        let entry = TimeEntry {
            id: object::new(ctx),  // 创建对象 UID
            timestamp,
            blobId,
        };

        // 将 TimeEntry 对象存储到表中，以账户地址为键
        Table::add(&mut store.entries, account, entry);
    }

    // 通过账户地址查询对象
    public fun get_time_entry(store: &TimeEntryStore, account: Address): &TimeEntry {
        Table::borrow(&store.entries, account)
    }








}